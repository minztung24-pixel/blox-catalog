return function(FruitModels)
    local gui=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    assert(not gui:FindFirstChild("__ReplicatedSpinnerInstances"),"Use the isolated Studio fixture")
    local elsewhere=Instance.new("Folder",gui)
    local holder=Instance.new("Folder",gui);holder.Name="__ReplicatedSpinnerInstances"
    local cache=FruitModels.new(function()return false end)
    local item={id="1516",name="Magnet",category="Fruits"}
    local skin={id="1525",name="Arcsteel Magnet",category="Fruit Skins",isPhysicalFruit=true}
    local function source(class,id,parent)
        local model=Instance.new(class,parent);model.Name="Native preview"
        model:SetAttribute("ItemId",id)
        local handle=Instance.new("Part",model);handle.Name="Handle"
        local fx=Instance.new("ParticleEmitter",handle);fx.Enabled=false;fx.Rate=7
        local animation=Instance.new("Animation",model);animation.AnimationId="rbxassetid://1"
        Instance.new("ModuleScript",model)
        Instance.new("RemoteEvent",model)
        return model
    end
    local ok,message=pcall(function()
        local model=source("Model",1516,holder)
        local clean=assert(cache:capture(item,model),"Recognize a native preview Model by exact physical ItemId")
        assert(cache:available(item) and cache:load(item)==clean,"Preview works without an RBXM file")
        assert(clean.Handle.ParticleEmitter.Rate==7 and not clean.Handle.ParticleEmitter.Enabled)
        assert(clean:FindFirstChildWhichIsA("Animation",true).AnimationId=="rbxassetid://1")
        assert(not clean:FindFirstChildWhichIsA("LuaSourceContainer",true) and not clean:FindFirstChildWhichIsA("RemoteEvent",true))
        assert(model.Parent==holder and model:FindFirstChildWhichIsA("ModuleScript"),"Leave native source intact")
        assert(cache:capture(skin,model)==nil,"Never substitute base fruit for skin")
        model:SetAttribute("ItemId",nil)
        assert(cache:capture(item,model)==nil,"A matching name without ItemId is insufficient")
        model:SetAttribute("ItemId",1516)
        model.Parent=elsewhere
        assert(cache:capture(item,model)==nil,"Do not accept arbitrary replicated Models")
        model.Parent=holder
        local owned=source("Tool",1525,holder);owned:SetAttribute("BloxCatalogOwned",true)
        assert(cache:capture(skin,owned)==nil,"Do not learn from Catalog clones")
        owned:SetAttribute("BloxCatalogOwned",nil)
        assert(cache:capture(skin,owned),"Native preview Tools are supported too")
        local genuine=source("Tool",1516,elsewhere)
        local held=assert(cache:capture(item,genuine))
        assert(cache:capture(item,model)==held,"A preview must not replace a captured genuine Tool")
        holder:Destroy()
        assert(cache:load(item)==held and cache:available(skin),"Keep sanitized snapshots after native previews disappear")
    end)
    cache:close();holder:Destroy();elsewhere:Destroy()
    assert(ok,message)
    assert(cache:capture(item,nil)==nil,"Closed cache rejects new sources")
    return "Native fruit preview source assertions passed"
end
