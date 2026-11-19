return function(NativeItems)
    local values = {[1113] = {Quantity = 1, IsOwned = true}, [1393] = {Quantity = 3, IsOwned = true}}
    local writes, forwarded, equipped = 0, 0, 0
    local failKey, ignoreKey, coerceOnce, failAfterWrite
    local service = {IS_CLIENT = true, IsInitialized = true, KEYS = {
        QUANTITY = "Quantity", IS_OWNED = "IsOwned", IS_STOCKED = "IsStocked", IS_EQUIPPED = "IsEquipped",
    }}
    function service:GetItems()
        assert(self == service)
        return {{Key = "Quantity", ItemId = 1113, Value = 1}, {Key = "IsOwned", ItemId = 1113, Value = true}}
    end
    function service:ReadItem(key, id, uid)
        assert(self == service and typeof(key) == "string" and typeof(id) == "number" and uid == nil)
        return values[id] and values[id][key]
    end
    function service:WriteTempItem(key, id, uid, value)
        assert(self == service and typeof(key) == "string" and typeof(id) == "number" and uid == nil)
        assert(key == "Quantity", "Only quantity may be written; game flags must stay untouched")
        writes += 1
        if key == failKey then error("fixture write failed") end
        if key == ignoreKey then return false end
        if key == "Quantity" and coerceOnce then value = false; coerceOnce = false end
        if value == false or value == 0 then value = nil end
        values[id] = values[id] or {}; values[id][key] = value
        if failAfterWrite then failAfterWrite = false; error("fixture failure after write") end
    end
    local Future = {from = function(fn) return {future = true, value = fn()} end}
    local Result = {ok = function() return {ok = true} end, err = function(message) return {ok = false, error = message} end}
    local equipAction = {}
    local original = function() forwarded += 1; return {original = true} end
    local remote = {invokeAction = original}
    local bridge = NativeItems.new(service, remote, Future, Result, {[equipAction] = true}, function()
        equipped += 1; return true
    end)
    local item = {id = "1393", name = "Buddha", category = "Fruits"}
    assert(bridge:sync(item, 2, false, false) and values[1393].Quantity == 5, "Add must reach the observed native quantity field")
    local response = remote.invokeAction(equipAction, 1393)
    assert(response.original and equipped == 0 and forwarded == 1, "Stock that existed before the panel must keep the game's normal Equip path")
    assert(not remote.invokeAction({}, 1393).value.ok and forwarded == 1, "Synthetic transactions must not reach server actions")
    assert(remote.invokeAction({}, 999).original and forwarded == 2, "Unrelated IDs must keep their handler")
    assert(remote.invokeAction({}, 1393, "real-uid").original and forwarded == 3, "Networked original copies must keep their handler")
    values[1393].Quantity = 20
    assert(bridge:sync(item, 3, false, false) and values[1393].Quantity == 23, "An external update must become the new baseline")
    assert(bridge:sync(item, 3, true, true) and values[1393].Quantity == 22)
    assert(bridge:restore(item) and values[1393].Quantity == 20, "Clear must restore the observed baseline")
    local empty = {id = "1525", name = "Arcsteel Magnet", category = "Fruits"}
    assert(bridge:sync(empty, 1, false, false) and values[1525].Quantity == 1)
    local localResponse = remote.invokeAction(equipAction, 1525)
    assert(localResponse.future and localResponse.value.ok and equipped == 1 and forwarded == 3, "An added-only item must use local Equip and return Future<Result>")
    assert(bridge:sync(empty, 1, true, true) and values[1525].Quantity == nil, "Equipping the final copy must accept the game's zero-to-nil normalization")
    assert(bridge:restore(empty) and values[1525].Quantity == nil)
    failKey = "Quantity"
    assert(not bridge:sync(item, 1, false, false) and values[1393].Quantity == 20, "A failed native write must roll back")
    failKey = nil
    ignoreKey = "Quantity"
    local rejected, message = bridge:sync(item, 1, false, false)
    assert(not rejected and message:find("Quantity", 1, true), "A failed write must identify its exact key")
    assert(bridge.lastFailure and bridge.lastFailure.itemId == 1393 and bridge.lastFailure.actualType == "number")
    ignoreKey = nil
    coerceOnce = true
    assert(not bridge:sync(item, 1, false, false) and values[1393].Quantity == 20, "A mismatched value written by the setter must be rolled back")
    failAfterWrite = true
    assert(not bridge:sync(item, 1, false, false) and values[1393].Quantity == 20, "A setter that throws after updating must also roll back")
    assert(bridge:close() and remote.invokeAction == original)
    local bad = table.clone(service); bad.ReadItem = function() return nil end
    local before = writes
    assert(not pcall(NativeItems.new, bad, remote, Future, Result, {}, function() end) and writes == before)
    return "NativeItems assertions passed: native quantity, Future<Result>, local Equip, action guard, external updates, rollback, restore"
end
