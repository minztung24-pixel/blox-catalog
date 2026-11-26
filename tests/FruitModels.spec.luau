return function(FruitModels, Equipment)
    local item = {id = "1525", name = "Arcsteel Magnet", storageKey = "Arcsteel Magnet", category = "Fruit Skins", isPhysicalFruit = true}
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
        local native = Instance.new("Tool");native.Name="Arcsteel Magnet Fruit";native:SetAttribute("ItemId",1525)
        native.Parent=Instance.new("Folder")
        Instance.new("Part",native).Name="Handle"
        local fruit=Instance.new("Model",native);fruit.Name="Fruit"
        Instance.new("AnimationController",fruit)
        local animation=Instance.new("Animation",fruit);animation.AnimationId="rbxassetid://90561160320604"
        local emitter=Instance.new("ParticleEmitter",native.Handle);emitter.Rate=7;emitter.Enabled=false
        Instance.new("Script",native).Name="FruitAnimator"
        local nativeParent=native.Parent
        table.insert(originals,nativeParent)
        assert(cache:capture({id="999",category="Fruits"},native)==nil,"Do not cache a mismatched ItemId")
        native:SetAttribute("BloxCatalogOwned",true)
        assert(cache:capture(item,native)==nil,"Never learn from another catalog clone")
        native:SetAttribute("BloxCatalogOwned",nil)
        local racing
        racing=FruitModels.new(function()return true end,function()return "fixture" end,function()
            assert(racing:capture(item,native))
            local imported=Instance.new("Tool");Instance.new("Part",imported).Name="Handle"
            return {imported}
        end)
        assert(racing:load(item)==racing.models[item.id] and racing.native[item.id]==native,"An import finishing late must not replace a native template")
        racing:close()
        local captured=assert(cache:capture(item,native))
        assert(cache:load(item)==captured and cache:capture(item,native)==captured and reads==1,"Native template replaces imported data and is reused")
        assert(source.Parent==nil and captured:FindFirstChild("FruitAnimator")==nil,"Dispose old template and strip native scripts")
        assert(captured.Fruit.Animation.AnimationId==animation.AnimationId and captured.Handle.ParticleEmitter.Rate==7
            and not captured.Handle.ParticleEmitter.Enabled,"Keep actual animation ID and authored FX state")
        assert(native.Parent==nativeParent and native.FruitAnimator.Parent==native,"Leave the genuine Tool intact")
        nativeParent:Destroy()
        assert(cache:load(item)==captured,"Keep a safe template after the genuine Tool leaves")
        cache:close()
        assert(captured.Parent == nil and cache:load(item) == nil, "Closed cache must not reload files")
        local bad = FruitModels.new(function() return true end,function() return "fixture" end,function() error("fixture import denied") end)
        local model, err = bad:load(item)
        assert(model == nil and err:find("fixture import denied",1,true))
        bad:close()
        for _, case in ipairs({
            {id="1393",imported="78877647242196",expected="15123606541"},
            {id="1393",imported="15123606541",expected="15123606541"},
            {id="1525",imported="78877647242196",expected="78877647242196"},
        }) do
            local selected={id=case.id,name="Fixture",storageKey="Fixture",category="Fruits"}
            local original=Instance.new("Tool");original:SetAttribute("ItemId",tonumber(case.id))
            Instance.new("Part",original).Name="Handle"
            local fruit=Instance.new("Model",original);fruit.Name="Fruit"
            Instance.new("AnimationController",fruit)
            local idle=Instance.new("Animation",fruit);idle.Name="Idle";idle.AnimationId="rbxassetid://"..case.imported
            local migrated=FruitModels.new(function()return true end,function()return "fixture" end,function()return {original} end)
            local loaded=assert(migrated:load(selected))
            local correct=loaded.Fruit.Idle.AnimationId=="rbxassetid://"..case.expected
            migrated:close()
            assert(correct,"Correct only the verified Buddha export ID; preserve other IDs and fruits")
        end
        for _, kind in ipairs({"wrongId","multiple","noPart","wrongEmpyrean"}) do
            local a = Instance.new("Tool");a:SetAttribute("ItemId",kind=="wrongId" and 9999 or 1525)
            local selected=item
            if kind=="wrongEmpyrean" then
                a:SetAttribute("ItemId",nil);a.Name="Galaxy Empyrean Kitsune Fruit"
                selected={id="1041",name="Empyrean",storageKey="Empyrean (Kitsune)-Empyrean (Kitsune)",category="Fruits"}
            end
            if kind ~= "noPart" then Instance.new("Part",a).Name="Handle" end
            local objects = {a}
            if kind == "multiple" then table.insert(objects,Instance.new("Model")) end
            local rejected = FruitModels.new(function()return true end,function()return "fixture" end,function()return objects end)
            local loaded,reason=rejected:load(selected)
            assert(loaded==nil,"Reject "..kind)
            if kind=="wrongEmpyrean" then assert(reason:find("contains Galaxy",1,true),"Explain the mislabeled export")end
            for _, object in ipairs(objects) do assert(object.Parent==nil and #object:GetChildren()==0) end
            rejected:close()
        end
        for _,case in ipairs({{id="1041",name="Empyrean Fruit"},{id="1042",name="Galaxy Empyrean Kitsune Fruit"}})do
            local source=Instance.new("Tool");source.Name=case.name
            Instance.new("Part",source).Name="Handle"
            local accepted=FruitModels.new(function()return true end,function()return "fixture" end,function()return {source}end)
            local loaded=accepted:load({id=case.id,name=case.name,storageKey=case.name,category="Fruits"})
            accepted:close()
            assert(loaded,"Accept the correct Empyrean and preserve Galaxy")
        end
    end)
    cache:close()
    for _, tool in ipairs(originals) do tool:Destroy() end
    assert(ok,message)
    return "Fruit model assertions passed"
end
