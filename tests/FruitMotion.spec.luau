return function(Equipment)
    local root = Instance.new("Folder")
    local tool = Instance.new("Tool",root);tool:SetAttribute("BloxCatalogOwned",true)
    local fruit = Instance.new("Model",tool)
    local controller = Instance.new("AnimationController",fruit)
    local idle = Instance.new("Animation",fruit);idle.Name="Idle";idle.AnimationId="rbxassetid://15123685330"
    local eat = Instance.new("Animation",fruit);eat.Name="Eat";eat.AnimationId="rbxassetid://10851812420"
    local loads,plays,stops,destroys = 0,0,0,0
    local track = {Play=function()plays+=1 end,Stop=function()stops+=1 end,Destroy=function()destroys+=1 end}
    local motion = Equipment.fruitMotion(tool,function(message)error(message)end,function(animator,animation)
        assert(animator.Parent==controller and animation==idle,"Only the rig's own Idle may play")
        loads+=1;return track
    end)
    local ok,err=pcall(function()
        motion:setActive(true)
        assert(loads==0,"Do not load tracks before Workspace ancestry")
        root.Parent=workspace
        motion:setActive(true);motion:setActive(true)
        assert(loads==1 and plays==1 and track.Looped and track.Priority==Enum.AnimationPriority.Idle)
        motion:setActive(false);assert(stops==1)
        motion:setActive(true);assert(loads==1 and plays==2,"Reuse the track when re-equipped")
        motion:close();motion:close();motion:setActive(true)
        assert(destroys==1 and loads==1 and plays==2,"Cleanup is idempotent and prevents restart")
        idle.Name="Animation";idle.AnimationId="rbxassetid://15123606541"
        local nativeMotion=Equipment.fruitMotion(tool,function(message)error(message)end,function(_,animation)
            assert(animation==idle,"Use the native Buddha Animation beside its controller")
            loads+=1;return track
        end)
        nativeMotion:setActive(true)
        assert(loads==2 and plays==3,"A native Animation must play without an Idle child")
        nativeMotion:close()
    end)
    motion:close();root:Destroy();assert(ok,err)
    return "Fruit motion assertions passed"
end
