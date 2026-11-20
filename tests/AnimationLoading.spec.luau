return function(Equipment)
    local function await(check)
        local deadline=os.clock()+1
        repeat task.wait(.01) until check() or os.clock()>deadline
        assert(check(),"Animation load did not complete")
    end
    local root=Instance.new("Folder")
    local animation=Instance.new("Animation",root);animation.AnimationId="rbxassetid://123"
    local loaders,assets={},{}
    local calls,loads=0,0
    local animator={LoadAnimation=function(_,actual)assert(actual==animation);loads+=1;return {loaded=true}end}
    local ok,message=pcall(function()
        local loader=Equipment.animationLoader(function(objects,callback)
            calls+=1;table.insert(assets,objects[1])
            assert(typeof(objects[1])=="Instance" and objects[1]:IsA("Animation") and objects[1]~=animation
                and objects[1].AnimationId==animation.AnimationId and objects[1].Parent==nil,"Use a private typed Animation")
            task.wait(.03);callback(animation.AnimationId,Enum.AssetFetchStatus.Success)
        end,.2)
        table.insert(loaders,loader)
        local first,second
        task.spawn(function()first=loader:load(animator,animation)end)
        task.spawn(function()second=loader:load(animator,animation)end)
        await(function()return first and second end)
        assert(calls==1 and loads==2,"Share one asset request, load tracks separately for each Animator")
        assert(loader:load(animator,animation).loaded and calls==1,"Reuse the completed asset result")
        for _,mode in ipairs({"failed","timeout","closed"}) do
            local requests=0
            local rejected=Equipment.animationLoader(function(objects,callback)
                requests+=1;table.insert(assets,objects[1])
                if mode=="failed" then callback(animation.AnimationId,Enum.AssetFetchStatus.Failure)
                else task.wait(60) end
            end,.06)
            table.insert(loaders,rejected)
            local finished,accepted,reason=false,nil,nil
            task.spawn(function()accepted,reason=pcall(rejected.load,rejected,animator,animation);finished=true end)
            if mode=="closed" then await(function()return requests==1 end);rejected:close() end
            await(function()return finished end)
            assert(not accepted and tostring(reason):find("rbxassetid://123",1,true),"Report the exact failed ID")
            assert(not pcall(rejected.load,rejected,animator,animation) and requests==1,"Do not loop requests after failure/close")
        end
        for _,asset in ipairs(assets) do
            assert(not pcall(function()asset.Parent=root end),"Dispose temporary preload objects")
        end
        assert(animation.Parent==root and animation.AnimationId=="rbxassetid://123","Keep the authored Animation intact")
    end)
    for _,loader in ipairs(loaders) do loader:close() end
    root:Destroy();assert(ok,message)
    return "Animation loading assertions passed: shared requests, typed assets, cached failures, timeout and cleanup"
end
