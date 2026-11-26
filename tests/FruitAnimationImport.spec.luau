return function(FruitModels,Equipment,FruitAnimations)
    local item={id="990000",name="Fixture",storageKey="Fixture",category="Fruit Skins",isPhysicalFruit=true}
    local parent=Instance.new("Folder")
    local function fixture()
        local tool=Instance.new("Tool",parent);tool:SetAttribute("ItemId",tonumber(item.id))
        Instance.new("Part",tool).Name="Handle"
        local fruit=Instance.new("Model",tool);fruit.Name="Fruit"
        Instance.new("AnimationController",fruit)
        local idle=Instance.new("Animation",fruit);idle.Name="Idle";idle.AnimationId="rbxassetid://1"
        return tool
    end
    local original=fixture()
    local clean=assert(Equipment.clone(original,item))
    FruitAnimations.references[item.id]={signature=FruitAnimations.signature(clean),originalId="rbxassetid://1",animationId="rbxassetid://2"}
    clean:Destroy()
    local cache=FruitModels.new(function()return true end,function()return "fixture" end,function()return {original} end)
    local ok,message=pcall(function()
        assert(cache:load(item).Fruit.Idle.AnimationId=="rbxassetid://2","Imported model must use its verified animation reference")
        local native=fixture()
        assert(cache:capture(item,native).Fruit.Idle.AnimationId=="rbxassetid://1","Native templates retain their real animation")
        assert(native.Fruit.Idle.AnimationId=="rbxassetid://1","Leave the real Tool unchanged")
    end)
    cache:close();parent:Destroy();FruitAnimations.references[item.id]=nil
    assert(ok,message)
    return "Fruit animation import assertions passed"
end
