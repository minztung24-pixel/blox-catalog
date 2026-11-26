return function(Inventory, Catalog)
    local state = Inventory.new()
    local first = assert(Catalog.byId["1393"], "Missing observed Buddha physical ID")
    local permanent = assert(Catalog.byId["372"], "Missing permanent Buddha ID")
    assert(first.category == "Fruits" and permanent.category == "Permanent")
    assert(first.iconRectSize[1] == 150 and first.rarity == "Legendary")
    assert(#Catalog.search("1393", "Fruits") == 1)
    assert(#Catalog.search("MYTHICAL", "Fruit Skins") > 0)
    assert(#Catalog.search("[", "Fruits") == 0, "Search must use literal characters")
    assert(Catalog.byId["1525"].category=="Fruit Skins" and Catalog.byId["1525"].isPhysicalFruit)
    assert(Catalog.byId["1042"].category=="Fruit Skins" and Catalog.byId["1042"].isPhysicalFruit)
    assert(Catalog.byId["1516"].category=="Fruits" and Catalog.byId["1424"].category=="Fruits")
    for id,base in pairs({["1041"]="1423",["1060"]="1424",["1601"]="1422",["814"]="1430"})do
        local variant=Catalog.byId[id]
        assert(variant.category=="Fruit Skins" and variant.isPhysicalFruit and variant.baseFruitId==base)
        assert(Catalog.byId[base].category=="Fruits")
        assert(#Catalog.search(id,"Fruits")==0,"Variant must not remain in base-fruit search")
    end
    assert(Catalog.byId["1537"].hiddenInCatalog and Catalog.byId["1538"].hiddenInCatalog)
    assert(#Catalog.search("1537","Fruit Skins")==0,"Default Magnet skin is represented by its base fruit")
    local arcsteel=Catalog.search("1538","Fruit Skins")
    assert(#arcsteel==1 and arcsteel[1].id=="1525","Skin alias resolves to its physical model card")
    assert(Inventory.add(state, first) and Inventory.add(state, first))
    Inventory.clear(state, first.id)
    assert(state.items[first.id] == nil)
    Inventory.add(state, first)
    assert(Inventory.undoClear(state) and state.items[first.id].count == 3, "Undo must merge later additions")
    assert(not Inventory.undoClear(state), "Undo must be consumed once")
    Inventory.add(state, permanent)
    Inventory.clear(state)
    Inventory.clear(state)
    assert(Inventory.undoClear(state) and state.items[first.id].count == 3)
    assert(state.items[permanent.id].count == 1, "No-op Clear must preserve the undo batch")
    assert(not Inventory.setBalance(state, "-1", "0"))
    assert(not Inventory.setBalance(state, "9007199254740992", "0"))
    assert(Inventory.setBalance(state, "12345", "0") and state.balance.beli == 12345)
    assert(not Inventory.gift(state, first, "Someone"), "Only permanent items may be simulated as gifts")
    assert(not Inventory.gift(state, permanent, "bad name"))
    assert(Inventory.gift(state, permanent, "Player_123") and #state.gifts == 1)
    assert(state.items[permanent.id].count == 1, "Gift simulation must not consume inventory")
    local native = Inventory.new()
    local quantity, fail = 0, false
    native.native = {
        sync = function(_, _, count) if fail then return false, "write failed" end; quantity = count; return true end,
        restore = function() if fail then return false, "restore failed" end; quantity = 0; return true end,
    }
    local removed = 0
    native.removeEquipment = function() removed += 1 end
    assert(Inventory.add(native, first) and quantity == 1, "Add must synchronize Items before reporting success")
    fail = true
    assert(not Inventory.add(native, first) and native.items[first.id].count == 1)
    assert(not Inventory.clear(native) and native.items[first.id] and removed == 0, "Failed restore must preserve stock and equipment")
    fail = false
    assert(Inventory.clear(native) and quantity == 0 and removed == 1)
    assert(Inventory.undoClear(native) and quantity == 1 and native.items[first.id].count == 1)
    return "Simulation assertions passed: real IDs/icons, literal search, Add/Clear/Undo, balance validation, simulated gifts"
end
