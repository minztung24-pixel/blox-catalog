return function(FruitModels)
    local players=game:GetService("Players")
    local actual=players.LocalPlayer
    local character=actual.Character or actual.CharacterAdded:Wait()
    local localCharacter=Instance.new("Model",workspace)
    local npc=Instance.new("Model",workspace);Instance.new("Humanoid",npc)
    -- Reuse the real Studio character as the observed player, with a separate observing-player fixture.
    local observing={Character=localCharacter,DescendantAdded=actual.DescendantAdded}
    function observing:FindFirstChildOfClass(class)return actual:FindFirstChildOfClass(class)end
    local item={id="1516",name="Magnet",category="Fruits"}
    local skin={id="1525",name="Arcsteel Magnet",category="Fruit Skins",isPhysicalFruit=true}
    local cache=FruitModels.new(function()return false end)
    local sources={}
    local function source(parent,id,owned)
        local tool=Instance.new("Tool");tool:SetAttribute("ItemId",id)
        if owned then tool:SetAttribute("BloxCatalogOwned",true)end
        local part=Instance.new("Part",tool);part.Name="Handle";part.Transparency=1;part.CanCollide=false;part.CanTouch=false;part.Massless=true
        table.insert(sources,tool);tool.Parent=parent
        return tool
    end
    local function waitFor(check)
        local deadline=os.clock()+2
        repeat task.wait(.02)until check()or os.clock()>deadline
        assert(check(),"Other-player physical fruit was not captured")
    end
    local ok,message=pcall(function()
        local held=source(character,1516)
        cache:watch(observing,{[item.id]=item,[skin.id]=skin},function()end)
        waitFor(function()return cache:available(item)end)
        assert(cache.native[item.id]==held and held.Parent==character,"Read existing player source without moving it")
        assert(not cache:available(skin),"Exact physical ItemId separates base and skin")
        held:Destroy()
        held=source(character,1516)
        waitFor(function()return cache.native[item.id]==held end)
        assert(cache:available(item),"A fresh observed source can replace a departed observed source")
        source(npc,1525)
        source(character,1525,true)
        task.wait(.05)
        assert(not cache:available(skin),"Ignore NPC and Catalog-owned lookalikes")
        local localHeld=source(localCharacter,1516)
        waitFor(function()return cache.native[item.id]==localHeld end)
        local best=cache.models[item.id]
        Instance.new("Attachment",held.Handle)
        task.wait(.05)
        assert(cache.models[item.id]==best,"Another player's late changes cannot replace a local native source")
        local later=source(character,1525)
        waitFor(function()return cache:available(skin)end)
        later:Destroy();held:Destroy()
        assert(cache:available(item)and cache:available(skin),"Keep snapshots after observed Tools disappear")
    end)
    cache:close()
    for _,tool in ipairs(sources)do tool:Destroy()end
    localCharacter:Destroy();npc:Destroy()
    assert(ok,message)
    return "Other-character fruit source assertions passed"
end
