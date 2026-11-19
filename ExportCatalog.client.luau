-- Export cached catalog metadata. Does not invoke remotes or change inventory.
local Export = {}
local fields = {"Index", "Display", "Quality", "Moveset", "Skin", "Type", "Category", "Product", "Gamepass"}

function Export.bounded(fn, seconds, ...)
    local arguments, result = table.pack(...), nil
    local worker = task.spawn(function()
        result = table.pack(pcall(fn, table.unpack(arguments, 1, arguments.n)))
    end)
    local deadline = os.clock() + seconds
    while not result and os.clock() < deadline do task.wait(0.02) end
    if result then return table.unpack(result, 1, result.n) end
    pcall(task.cancel, worker)
    return false, "source timed out"
end

local function serialize(value, context, depth)
    context.remaining -= 1
    if context.remaining < 0 or depth > 8 then
        context.issues.limit = true
        return nil
    end
    local kind = typeof(value)
    if kind == "string" then
        if #value > 2048 then context.issues.stringLimit = true end
        return value:sub(1, 2048)
    elseif kind == "number" then
        if value == value and math.abs(value) < math.huge then return value end
        context.issues.nonFiniteNumber = true
    elseif kind == "boolean" then
        return value
    elseif kind == "Vector2" then
        return {x = value.X, y = value.Y}
    elseif kind == "EnumItem" then
        return {name = value.Name, value = value.Value, enum = tostring(value.EnumType)}
    elseif kind == "table" then
        if context.seen[value] then context.issues.cycle = true; return nil end
        context.seen[value] = true
        local copy = {}
        for key, child in next, value do
            if context.remaining <= 0 then context.issues.limit = true; break end
            if typeof(key) == "string" or typeof(key) == "number" then
                local name = tostring(key)
                local lowered = name:lower()
                if lowered:find("secret", 1, true) or lowered:find("password", 1, true)
                    or lowered:find("securitykey", 1, true) or lowered:find("token", 1, true) then
                    context.issues.redacted = true
                elseif copy[name] ~= nil then
                    context.issues.keyCollision = true
                else
                    copy[name] = serialize(child, context, depth + 1)
                end
            else
                context.issues.unsupportedKey = true
            end
        end
        context.seen[value] = nil
        return copy
    elseif kind ~= "nil" then
        context.issues[kind] = true
    end
    return nil
end

local function collectRows(values, configOnly)
    local section = {records = {}, truncated = false}
    local deadline = os.clock() + 10
    for key, value in next, values do
        if #section.records >= 10000 or os.clock() >= deadline then
            section.truncated = true
            section.reason = "row or time limit"
            break
        end
        local context = {remaining = 2500, seen = {}, issues = {}}
        local row = {key = tostring(key), keyType = typeof(key), issues = {}}
        if configOnly and typeof(value) == "table" then
            local selected, fieldTypes = {}, {}
            for field, member in next, value do
                if typeof(field) == "string" then fieldTypes[field] = typeof(member) end
            end
            for _, field in ipairs(fields) do selected[field] = rawget(value, field) end
            row.data = serialize(selected, context, 0)
            row.fieldTypes = fieldTypes
        else
            row.data = serialize(value, context, 0)
        end
        for issue in pairs(context.issues) do table.insert(row.issues, issue) end
        table.sort(row.issues)
        if #row.issues > 0 then section.truncated = true end
        table.insert(section.records, row)
        if #section.records % 100 == 0 then task.wait() end
    end
    return section
end

function Export.collect(storage, loaded, importer, checkpoint)
    local report = {schemaVersion = 1, placeId = game.PlaceId, gameId = game.GameId,
        placeVersion = game.PlaceVersion, complete = false, modules = {}, sections = {}}
    local function save(stage)
        report.stage = stage
        if checkpoint then checkpoint(report) end
    end
    save("starting")
    for _, name in ipairs({"ItemConfig", "FruitInfo", "Spritesheets"}) do
        local entry = {status = "missing"}
        report.modules[name] = entry
        local module = storage:FindFirstChild(name)
        if module and module:IsA("ModuleScript") then
            entry.path = module:GetFullName()
            entry.status = "not cached"
            if loaded[module] then
                save("reading " .. name)
                local ok, exports = Export.bounded(importer, 3, module)
                entry.status = "error"
                if ok and typeof(exports) == "table" then
                    local values
                    if name == "ItemConfig" then
                        local getterOK, getter = pcall(function() return exports.dumpItems end)
                        if getterOK and typeof(getter) == "function" then
                            ok, values = Export.bounded(getter, 3)
                        else
                            ok, values = false, "dumpItems unavailable"
                        end
                    else
                        values = rawget(exports, name == "FruitInfo" and "DATA" or "MAP_WITH_EXT")
                    end
                    if ok and typeof(values) == "table" then
                        report.sections[name] = collectRows(values, name == "ItemConfig")
                        entry.status = "ok"
                        entry.count = #report.sections[name].records
                    else
                        entry.error = typeof(values) == "string" and values or "catalog table unavailable"
                    end
                else
                    entry.error = typeof(exports) == "string" and exports or "module export is not a table"
                end
            end
        end
        save("finished " .. name)
    end
    report.complete = true
    save("complete")
    return report
end

local RunService = game:GetService("RunService")
if not RunService:IsRunning() or not RunService:IsClient() then return Export end
assert(typeof(writefile) == "function", "writefile is required to save the catalog report")
assert(typeof(getloadedmodules) == "function", "getloadedmodules is required; no game modules were initialized")
local loadedOK, cached = pcall(getloadedmodules)
assert(loadedOK and typeof(cached) == "table", "Cannot list cached modules")
local loaded = {}
for _, module in pairs(cached) do
    if typeof(module) == "Instance" and module:IsA("ModuleScript") then loaded[module] = true end
end
local filename = "blox-fruits-catalog-data-v1-" .. tostring(game.PlaceId) .. ".json"
local HttpService = game:GetService("HttpService")
local report = Export.collect(game:GetService("ReplicatedStorage"), loaded, require, function(partial)
    local ok, err = pcall(writefile, filename, HttpService:JSONEncode(partial))
    assert(ok, "Cannot save catalog checkpoint: " .. tostring(err))
end)
print("Catalog saved: " .. filename .. " | complete=" .. tostring(report.complete))
for _, name in ipairs({"ItemConfig", "FruitInfo", "Spritesheets"}) do
    local entry = report.modules[name]
    local section = report.sections[name]
    print(name .. ": " .. entry.status .. " | records=" .. tostring(entry.count or 0)
        .. " | partial=" .. tostring(section and section.truncated or false))
end
return report
