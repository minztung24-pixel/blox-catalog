return function(FruitModels)
    local player=game:GetService("Players").LocalPlayer
    local gui=player:WaitForChild("PlayerGui")
    local backpack=player:WaitForChild("Backpack")
    assert(not gui:FindFirstChild("__ReplicatedSpinnerInstances"),"Use an isolated Studio session")
    local item={id="1516",name="Magnet",category="Fruits"}
    local skin={id="1525",name="Arcsteel Magnet",category="Fruit Skins",isPhysicalFruit=true}
    local items={[item.id]=item,[skin.id]=skin}
    local cache=FruitModels.new(function()return false end)
    local holder,held,owned,late,afterClose
    local changes=0
    local function waitFor(check)
        local deadline=os.clock()+2
        repeat task.wait(.02)until check()or os.clock()>deadline
        assert(check(),"Native source watcher did not update")
    end
    local function handle(parent)
        local part=Instance.new("Part");part.Name="Handle";part.Anchored=true;part.CanTouch=false;part.Transparency=1;part.Parent=parent
        return part
    end
    local ok,message=pcall(function()
        cache:watch(player,items,function()changes+=1 end)
        holder=Instance.new("Folder");holder.Name="__ReplicatedSpinnerInstances";holder.Parent=gui
        local model=Instance.new("Model");model:SetAttribute("ItemId",1516);model.Parent=holder
        task.wait(.05)
        assert(not cache:available(item),"A partial root with no BasePart is not a model")
        handle(model)
        waitFor(function()return cache:available(item)end)
        local first=cache.models[item.id]
        assert(not cache:available(skin),"Base fruit must not satisfy its skin")
        local idle=Instance.new("Animation");idle.Name="Idle";idle.AnimationId="rbxassetid://1";idle.Parent=model
        local fx=Instance.new("ParticleEmitter");fx.Enabled=false;fx.Rate=7;fx.Parent=model.Handle
        Instance.new("ModuleScript",model)
        Instance.new("RemoteEvent",model)
        waitFor(function()return cache.models[item.id]~=first end)
        local updated=cache.models[item.id]
        assert(updated:FindFirstChild("Idle",true).AnimationId==idle.AnimationId,"Keep late replicated animations")
        assert(updated.Handle.ParticleEmitter.Rate==7 and not updated.Handle.ParticleEmitter.Enabled)
        assert(not updated:FindFirstChildWhichIsA("LuaSourceContainer",true)and not updated:FindFirstChildWhichIsA("RemoteEvent",true))
        assert(model.Parent==holder and model:FindFirstChildWhichIsA("ModuleScript"),"Never alter native sources")
        held=Instance.new("Tool");held:SetAttribute("ItemId",1516);handle(held);held.Parent=backpack
        waitFor(function()return cache.native[item.id]==held end)
        local best=cache.models[item.id]
        Instance.new("Attachment",model.Handle)
        task.wait(.05)
        assert(cache.models[item.id]==best,"Late preview changes cannot replace a captured genuine Tool")
        owned=Instance.new("Tool");owned:SetAttribute("ItemId",1525);owned:SetAttribute("BloxCatalogOwned",true);handle(owned);owned.Parent=workspace
        task.wait(.05)
        assert(not cache:available(skin),"Ignore Catalog-owned sources")
        late=Instance.new("Tool");handle(late);late.Parent=workspace
        task.wait(.05)
        late:SetAttribute("ItemId",1525)
        waitFor(function()return cache:available(skin)end)
        holder:Destroy();held:Destroy();late:Destroy()
        assert(cache:available(item)and cache:available(skin),"Retain safe snapshots after native cleanup")
        task.wait(.05)
        late=Instance.new("Tool");late:SetAttribute("ItemId",1525);handle(late);late.Parent=workspace
        local before=changes
        cache:close()
        afterClose=Instance.new("Tool");afterClose:SetAttribute("ItemId",1525);handle(afterClose);afterClose.Parent=workspace
        task.wait(.05)
        assert(changes==before and next(cache.models)==nil,"Close disconnects source listeners and cancels pending capture")
        assert(late.Parent==workspace and afterClose.Parent==workspace,"Closing the watcher never destroys native sources")
    end)
    cache:close()
    for _,node in pairs({holder,held,owned,late,afterClose})do node:Destroy()end
    assert(ok,message)
    return "Passive native fruit source assertions passed"
end
