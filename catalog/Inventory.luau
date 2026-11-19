local Inventory = {}
function Inventory.new()
    return {items = {}, balance = {beli = 0, fragments = 0}, gifts = {}}
end
function Inventory.add(state, item)
    local row = state.items[item.id]
    local count = (row and row.count or 0) + 1
    if count > 9007199254740991 then return false, "Quantity limit reached" end
    if state.native then
        local ok, err = state.native:sync(item, count, row and row.tool and row.tool.Parent ~= nil, row and row.equipped)
        if not ok then return false, err end
    end
    if row then
        row.count += 1
    else
        state.items[item.id] = {item = item, count = 1}
    end
    return true
end
function Inventory.clear(state, id)
    local removed = {}
    for key, row in pairs(state.items) do
        if id == nil or key == id then
            if state.native then
                local ok, err = state.native:restore(row.item)
                if not ok then
                    if next(removed) then state.lastClear = removed end
                    return false, err
                end
            end
            removed[key] = {item = row.item, count = row.count}
            if state.removeEquipment then state.removeEquipment(key) end
            state.items[key] = nil
        end
    end
    if next(removed) then state.lastClear = removed end
    return true
end
function Inventory.undoClear(state)
    if not state.lastClear then return false end
    for id, row in pairs(state.lastClear) do
        local current = state.items[id]
        if current and current.count > 9007199254740991 - row.count then return false end
    end
    for id, row in pairs(state.lastClear) do
        local current = state.items[id]
        if state.native then
            local ok, err = state.native:sync(row.item, row.count + (current and current.count or 0),
                current and current.tool and current.tool.Parent ~= nil, current and current.equipped)
            if not ok then return false, err end
        end
        if current then current.count += row.count else state.items[id] = row end
        state.lastClear[id] = nil
    end
    state.lastClear = nil
    return true
end
function Inventory.setBalance(state, beli, fragments)
    local function parse(text)
        if not text:match("^%d+$") then return nil end
        local value = tonumber(text)
        return value and value <= 9007199254740991 and value or nil
    end
    local money, shards = parse(beli), parse(fragments)
    if not money or not shards then return false end
    state.balance = {beli = money, fragments = shards}
    return true
end
function Inventory.gift(state, item, username)
    username = username:match("^%s*(.-)%s*$")
    if item.category ~= "Permanent" or #username < 3 or #username > 20 or not username:match("^[A-Za-z0-9_]+$") then return false end
    table.insert(state.gifts, 1, {id = item.id, name = item.name, recipient = username})
    if #state.gifts > 50 then table.remove(state.gifts) end
    return true
end
return Inventory
