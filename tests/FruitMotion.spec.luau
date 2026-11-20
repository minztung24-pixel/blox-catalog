return function(Equipment)
    local function await(check)
        local deadline=os.clock()+1
        repeat task.wait(.01) until check() or os.clock()>deadline
        assert(check(),"Fruit motion did not reach the expected state")
    end
    local root=Instance.new("Folder")
    local tool=Instance.new("Tool",root);tool:SetAttribute("BloxCatalogOwned",true)
    local fruit=Instance.new("Model",tool)
    local controller=Instance.new("AnimationController",fruit)
    local idle=Instance.new("Animation",fruit);idle.Name="Idle";idle.AnimationId="rbxassetid://15123685330"
    local eat=Instance.new("Animation",fruit);eat.Name="Eat";eat.AnimationId="rbxassetid://10851812420"
    local loads,plays,stops,destroys=0,0,0,0
    local function track(length)
        return {Length=length,Play=function()plays+=1 end,Stop=function()stops+=1 end,Destroy=function()destroys+=1 end}
    end
    local motions,notifications={},{}
    local function notify(message)table.insert(notifications,message)end
    local waiting=track(0)
    local motion=Equipment.fruitMotion(tool,notify,function(animator,animation)
        assert(animator.Parent==controller and animation==idle,"Use only the rig's own idle Animation")
        loads+=1;return waiting
    end,.2)
    table.insert(motions,motion)
    local ok,message=pcall(function()
        motion:setActive(true);task.wait(.01)
        assert(loads==0,"Do not load tracks outside Workspace")
        root.Parent=workspace
        motion:setActive(true);motion:setActive(true);await(function()return loads==1 end)
        assert(plays==0,"Never play a zero-length track")
        waiting.Length=5;await(function()return plays==1 end)
        assert(waiting.Looped and waiting.Priority==Enum.AnimationPriority.Idle)
        assert(tool:GetAttribute("BloxCatalogAnimationStatus")=="Ready")
        motion:setActive(false);assert(stops==1)
        motion:setActive(true);await(function()return plays==2 end)
        assert(loads==1,"Re-equip reuses the existing track")
        motion:close();motion:close();motion:setActive(true)
        assert(destroys==1 and loads==1,"Cleanup is idempotent")
        idle.Name="Animation";idle.AnimationId="rbxassetid://15123606541"
        local delayed=Equipment.fruitMotion(tool,notify,function(_,animation)
            assert(animation==idle,"Accept the captured native Buddha Animation name")
            loads+=1;task.wait(.04);return track(5)
        end,.2)
        table.insert(motions,delayed)
        delayed:setActive(true);await(function()return loads==2 end)
        delayed:setActive(false);task.wait(.06)
        assert(plays==2,"Unequip during load must prevent late playback")
        delayed:setActive(true);await(function()return plays==3 end)
        assert(loads==2,"A completed track remains reusable after loading while unequipped")
        delayed:close()
        local failedLoads=0
        local failed=Equipment.fruitMotion(tool,notify,function()failedLoads+=1;return track(0)end,.05)
        table.insert(motions,failed)
        failed:setActive(true);await(function()return tool:GetAttribute("BloxCatalogAnimationStatus")=="Failed" end)
        assert(plays==3 and tool:GetAttribute("BloxCatalogAnimationError"):find(idle.AnimationId,1,true))
        failed:setActive(false);failed:setActive(true);task.wait(.03)
        assert(failedLoads==1,"Do not reload a track that timed out")
        failed:close()
        local closing=Equipment.fruitMotion(tool,notify,function()task.wait(.05);return track(5)end,.2)
        table.insert(motions,closing)
        closing:setActive(true);task.wait(.01);closing:close();task.wait(.06)
        assert(plays==3,"Close must prevent delayed playback")
    end)
    for _,active in ipairs(motions) do active:close() end
    root:Destroy();assert(ok,message)
    return "Fruit motion assertions passed: readiness, track reuse, stale equip prevention, native names and bounded failure"
end
