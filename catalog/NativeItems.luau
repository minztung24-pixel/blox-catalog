local NativeItems = {}

function NativeItems.new(service, remote, Future, Result, equipActions, onEquip, hook)
    assert(service.IS_CLIENT == true and service.IsInitialized == true, "Item cache is not initialized")
    assert(typeof(service.ReadItem) == "function" and typeof(service.WriteTempItem) == "function", "Item cache API unavailable")
    assert(typeof(Future.from) == "function" and typeof(Result.ok) == "function" and typeof(Result.err) == "function", "Native action result API unavailable")
    assert(typeof(remote.invokeAction) == "function" and (hook or not table.isfrozen(remote)), "Native actions cannot be guarded")
    local verified = 0
    for _, row in ipairs(service:GetItems()) do
        if typeof(row) == "table" and (typeof(row.Value) == "number" or typeof(row.Value) == "boolean") then
            local ok, value = pcall(service.ReadItem, service, row.Key, row.ItemId, row.NetworkedUID)
            if ok and value == row.Value then verified += 1 end
            if verified >= 2 then break end
        end
    end
    assert(verified >= 2, "Native read signature could not be verified")
    local keys = assert(service.KEYS, "Native item keys unavailable")
    local quantityKey = assert(keys.QUANTITY, "Native quantity key unavailable")
    local bridge = {entries = {}}
    local function read(id) return service:ReadItem(quantityKey, id, nil) end
    local function scalar(value)
        local kind = typeof(value)
        if kind == "number" or kind == "string" or kind == "boolean" or kind == "nil" then return tostring(value):sub(1, 120) end
        return "<" .. kind .. ">"
    end
    local function write(id, value, attempt)
        -- UserReplicationCache.Set stores zero and false as nil before notifying listeners.
        if value == 0 or value == false then value = nil end
        local returned = service:WriteTempItem(quantityKey, id, nil, value)
        local actual = read(id)
        if attempt then attempt.after = actual; attempt.observed = true end
        if actual ~= value then
            bridge.lastFailure = {itemId = id, key = tostring(quantityKey), expected = scalar(value), expectedType = typeof(value),
                actual = scalar(actual), actualType = typeof(actual), returnedType = typeof(returned)}
            error("Native write verification failed: " .. tostring(quantityKey) .. " / ID " .. id
                .. " / expected " .. scalar(value) .. " / actual " .. scalar(actual), 0)
        end
    end
    function bridge:sync(item, count, outsideStock)
        self.lastFailure = nil
        local id = tonumber(item.id)
        if not id then return false, "Invalid ItemId" end
        local entry = self.entries[id] or {item = item}
        local attempt = {}
        local desired
        local ok, err = pcall(function()
            local current = read(id)
            if not self.entries[id] or current ~= entry.written then entry.original = current end
            local originalQuantity = entry.original or 0
            assert(typeof(originalQuantity) == "number" and originalQuantity == originalQuantity
                and originalQuantity >= 0 and originalQuantity < math.huge and originalQuantity % 1 == 0, "Invalid native quantity")
            assert(typeof(count) == "number" and count >= 0 and count < math.huge and count % 1 == 0, "Invalid local quantity")
            local stock = math.max(0, count - (outsideStock and 1 or 0))
            assert(originalQuantity + stock <= 9007199254740991, "Native quantity limit reached")
            desired = originalQuantity + stock
            if desired == 0 then desired = nil end
            attempt.before = current
            attempt.started = true
            write(id, desired, attempt)
        end)
        if not ok then
            local failure = self.lastFailure
            if attempt.started and not attempt.observed then
                local readable, current = pcall(read, id)
                if readable and current == desired then attempt.after = current; attempt.observed = true end
            end
            if attempt.observed and attempt.after ~= attempt.before then
                local restored = pcall(function()
                    if read(id) == attempt.after then write(id, attempt.before) end
                end)
                if not restored then entry.written = attempt.after; self.entries[id] = entry end
            end
            self.lastFailure = failure
            return false, tostring(err)
        end
        entry.item = item; entry.written = desired
        self.entries[id] = entry
        return true
    end
    function bridge:restore(item)
        local id = tonumber(item.id)
        local entry = self.entries[id]
        if not entry then return true end
        local ok, err = pcall(function()
            -- Keep a replication update that superseded this script's local value.
            if read(id) == entry.written then write(id, entry.original) end
        end)
        if not ok then return false, tostring(err) end
        self.entries[id] = nil
        return true
    end
    local target, original = remote.invokeAction, remote.invokeAction
    local handler = function(action, id, uid, equipped)
        local entry = bridge.entries[id]
        if not entry or uid ~= nil then return original(action, id, uid, equipped) end
        if equipActions[action] and typeof(entry.original) == "number" and entry.original > 0 then
            return original(action, id, uid, equipped)
        end
        -- RemoteUtil returns Future<Result>; synthetic actions stay entirely local.
        return Future.from(function()
            if equipActions[action] then
                local called, ok, err = pcall(onEquip, entry.item)
                if called and ok then return Result.ok() end
                return Result.err(tostring(called and err or ok))
            end
            return Result.err("Simulated item: clear local copies before using native transactions")
        end)
    end
    if hook then original = hook(target, handler); assert(typeof(original) == "function", "Action hook failed")
    else remote.invokeAction = handler end
    function bridge:close()
        local items = {}
        for _, entry in pairs(self.entries) do table.insert(items, entry.item) end
        for _, item in ipairs(items) do
            local ok, err = self:restore(item)
            if not ok then return false, err end
        end
        local ok, err = pcall(function()
            if hook then hook(target, original)
            elseif remote.invokeAction == handler then remote.invokeAction = original end
        end)
        return ok, err
    end
    return bridge
end

function NativeItems.connect(onEquip)
    assert(typeof(getloadedmodules) == "function", "Open Items in Blox Fruits, then press Rescan")
    local loaded = {}
    for _, module in pairs(getloadedmodules()) do loaded[module] = true end
    local storage = game:GetService("ReplicatedStorage")
    local function cached(path)
        local module = storage
        for name in path:gmatch("[^.]+") do module = module and module:FindFirstChild(name) end
        assert(module and module:IsA("ModuleScript") and loaded[module], "Open Items, then Rescan: " .. path .. " not cached")
        local result
        local worker = task.spawn(function() result = table.pack(pcall(require, module)) end)
        local deadline = os.clock() + 3
        while not result and os.clock() < deadline do task.wait(0.03) end
        if not result then pcall(task.cancel, worker); error("Cached module timed out: " .. path) end
        assert(result[1], result[2])
        return result[2]
    end
    local service = cached("ItemReplicationService")
    local remote = cached("Controllers.UI.Inventory.RemoteUtil")
    local Future, Result, enums = cached("Packages.Future"), cached("Packages.Result"), cached("PseudoEnum")
    local actions = {}
    actions[assert(enums.InventoryAction.EquipFruit)] = true
    actions[assert(enums.InventoryAction.EquipItem)] = true
    local hook = typeof(hookfunction) == "function" and hookfunction or nil
    return NativeItems.new(service, remote, Future, Result, actions, onEquip, hook)
end

return NativeItems
