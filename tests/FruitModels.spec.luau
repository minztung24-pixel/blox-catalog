return function(FruitModels, Equipment)
    local item = {id = "1525", name = "Arcsteel Magnet", storageKey = "Arcsteel Magnet", category = "Fruits"}
    local path = "codex_fruit_studio/models/Arcsteel Magnet.rbxm"
    local cache, reads, originals = nil, 0, {}
    local function objects(uri)
        assert(uri == "local:" .. path)
        reads += 1
        local tool = Instance.new("Tool"); tool.Name = "Arcsteel Magnet Fruit"; tool:SetAttribute("ItemId", 1525)
        Instance.new("Part", tool).Name = "Handle"
        Instance.new("LocalScript", tool)
        Instance.new("RemoteFunction", tool)
        table.insert(originals, tool)
        return {tool}
    end
    cache = FruitModels.new(function(file) return file == path end,
        function(file) return "local:" .. file end, objects)
    local ok, message = pcall(function()
        assert(cache:path(item) == path)
        assert(cache:path({id=item.id,name=item.name,storageKey="Missing-Missing",category="Fruits"}) == path)
        assert(cache:path({id="1",name="../escape",storageKey="../escape",category="Fruits"}) == nil)
        assert(cache:path({id="1",name=item.name,storageKey=item.storageKey,category="Swords"}) == nil)
        local source = assert(cache:load(item))
        assert(source.Parent and source:GetAttribute("BloxCatalogOwned"))
        assert(not source:FindFirstChildWhichIsA("LuaSourceContainer",true))
        assert(not source:FindFirstChildWhichIsA("RemoteFunction",true))
        assert(source == cache:load(item) and reads == 1, "Reuse parsed files")
        assert(originals[1].Parent == nil and #originals[1]:GetChildren() == 0, "Dispose raw objects")
        local held = assert(Equipment.clone(source,item)); held:Destroy()
        cache:close()
        assert(source.Parent == nil and cache:load(item) == nil, "Closed cache must not reload files")
        local bad = FruitModels.new(function() return true end,function() return "fixture" end,function() error("fixture import denied") end)
        local model, err = bad:load(item)
        assert(model == nil and err:find("fixture import denied",1,true))
        bad:close()
        for _, kind in ipairs({"wrongId","multiple","noPart"}) do
            local a = Instance.new("Tool");a:SetAttribute("ItemId",kind=="wrongId" and 9999 or 1525)
            if kind ~= "noPart" then Instance.new("Part",a).Name="Handle" end
            local objects = {a}
            if kind == "multiple" then table.insert(objects,Instance.new("Model")) end
            local rejected = FruitModels.new(function()return true end,function()return "fixture" end,function()return objects end)
            assert(rejected:load(item)==nil,"Reject "..kind)
            for _, object in ipairs(objects) do assert(object.Parent==nil and #object:GetChildren()==0) end
            rejected:close()
        end
    end)
    cache:close()
    for _, tool in ipairs(originals) do tool:Destroy() end
    assert(ok,message)
    return "Fruit model assertions passed"
end
