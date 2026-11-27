-- Compare native playback with Catalog preload on invisible copies; no player Tool or transaction is touched.
assert(game.GameId==994732206 and type(readfile)=="function" and type(writefile)=="function","Run in Blox Fruits with Potassium")
local source=readfile("blox-catalog-sim-v12.lua")
local count
source,count=source:gsub("return UI%.start%(%)%s*$","return {Catalog=Catalog,Equipment=Equipment,FruitModels=FruitModels}")
assert(count==1,"Expected the standalone Catalog; do not start its UI")
local modules=assert(loadstring(source,"FruitPlaybackComparison"))()
local Http=game:GetService("HttpService")
local cache=modules.FruitModels.new()
local loader=modules.Equipment.animationLoader(nil,5)
local folder=Instance.new("Folder");folder.Name="BloxCatalogPlaybackComparison"
local targets={
    {"1424","Yeti",true},{"1413","Shadow",true},{"1395","Dark",true},
    {"1447","Dragon"},{"884","Dragon (West)"},{"1047","Ember"},{"1394","Flame"},
    {"1427","Lightning"},{"1389","Quake"},{"1430","Tiger"},{"814","Werewolf (Tiger)"},
}
local modes={"CatalogPreload","AnimatorImmediate","NativeControllerImmediate"}
local output="blox-catalog-fruit-playback-comparison-"..game.PlaceId..".json"
local report={schemaVersion=1,observedAt=DateTime.now():ToIsoDate(),catalogVersion=source:match("Blox Catalog v([%d%.]+)"),
    placeId=game.PlaceId,complete=false,conclusive=false,results={}}
local tool,motion,track,worker
local function save()writefile(output,Http:JSONEncode(report))end
local function cleanup()
    if worker then pcall(task.cancel,worker);worker=nil end
    if motion then motion:close();motion=nil end
    if track then pcall(track.Stop,track,0);pcall(track.Destroy,track);track=nil end
    if tool then tool:Destroy();tool=nil end
end
local function changed(a,b)return not a:FuzzyEq(b,.00001)end
assert(not changed(CFrame.new(),CFrame.new()) and changed(CFrame.new(),CFrame.new(.1,0,0)),"Pose detector self-check")
local function inspect(item,mode,row)
    local template,reason=cache:load(item)
    if not template then row.status="MissingModel";row.error=tostring(reason);return end
    tool=assert(modules.Equipment.clone(template,item),"No usable model")
    row.storageKey=item.storageKey
    row.authoredFx={total=0,enabled=0};row.animations={}
    local joints={}
    for _,node in ipairs(tool:GetDescendants())do
        if node:IsA("BasePart")then
            node.Transparency=1;node.Anchored=node==tool.Handle;node.CanCollide=false;node.CanTouch=false;node.CanQuery=false
        elseif node:IsA("ParticleEmitter")or node:IsA("Beam")or node:IsA("Trail")then
            row.authoredFx.total+=1;if node.Enabled then row.authoredFx.enabled+=1 end;node.Enabled=false
        elseif node:IsA("Light")or node:IsA("Fire")or node:IsA("Smoke")or node:IsA("Sparkles")then node.Enabled=false
        elseif node:IsA("Bone")or node:IsA("Motor6D")then table.insert(joints,node)
        elseif node:IsA("Animation")then table.insert(row.animations,node.AnimationId)end
    end
    local fruit=tool:FindFirstChild("Fruit")
    local controller=fruit and fruit:FindFirstChildOfClass("AnimationController")
    local animation=fruit and (fruit:FindFirstChild("Idle")or fruit:FindFirstChild("Animation"))
    if not controller or not animation or not animation:IsA("Animation")then row.status="MissingRig";return end
    row.animationId=animation.AnimationId;row.joints=#joints
    tool.Handle.CFrame=workspace.CurrentCamera.CFrame*CFrame.new(0,0,-12);tool.Parent=folder
    local animator=controller:FindFirstChildOfClass("Animator")or Instance.new("Animator",controller)
    pcall(function()animator.PreferLodEnabled=false end)
    local deadline=os.clock()+7
    if mode=="CatalogPreload"then
        motion=modules.Equipment.fruitMotion(tool,function()end,function(actualAnimator,actualAnimation)
            return loader:load(actualAnimator,actualAnimation)
        end,5)
        motion:setActive(true)
        repeat task.wait(.05)until tool:GetAttribute("BloxCatalogAnimationStatus")~="Loading"or os.clock()>deadline
        row.loadStatus=tool:GetAttribute("BloxCatalogAnimationStatus")
        if row.loadStatus~="Ready"then row.status="LoadFailed";row.error=tool:GetAttribute("BloxCatalogAnimationError");return end
        track=animator:GetPlayingAnimationTracks()[1]
    else
        local finished,success,message=false,nil,nil
        worker=task.spawn(function()
            success,message=pcall(function()
                if mode=="NativeControllerImmediate"then track=controller:LoadAnimation(animation)
                else track=animator:LoadAnimation(animation)end
                track.Looped=true;track:Play(0)
            end)
            finished=true
        end)
        repeat task.wait(.05)until finished or os.clock()>deadline
        if not finished then row.status="LoadTimedOut";return end
        worker=nil
        if not success then row.status="LoadFailed";row.error=tostring(message);return end
        while track.Length<=0 and os.clock()<deadline do task.wait(.05)end
    end
    if not track then row.status="NoTrack";return end
    row.length=track.Length;row.playing=track.IsPlaying
    if track.Length<=0 then row.status="NoLoadedClipData";return end
    track:AdjustSpeed(0)
    local previous,moved={},{}
    for phase=0,5 do
        track.TimePosition=track.Length*phase/6;task.wait(.1)
        for _,joint in ipairs(joints)do
            local pose=joint.Transform
            if previous[joint]and changed(previous[joint],pose)then moved[joint]=true end
            previous[joint]=pose
        end
    end
    row.movingJoints=0;for _ in pairs(moved)do row.movingJoints+=1 end
    row.status=row.movingJoints>0 and "PoseChangesObserved"or "NoPoseChangesObserved"
end
local started=os.clock()
local ok,message=pcall(function()
    assert(workspace.CurrentCamera,"Wait for the game camera")
    folder.Parent=workspace
    for _,target in ipairs(targets)do
        local item=assert(modules.Catalog.byId[target[1]],"Missing comparison item")
        assert(item.name==target[2]and item.isPhysicalFruit,"Comparison must use the exact physical fruit/skin")
        for _,mode in ipairs(modes)do
            local row={id=item.id,name=item.name,control=target[3]==true,mode=mode,status="Pending"}
            table.insert(report.results,row);save()
            local passed,failure=pcall(inspect,item,mode,row)
            cleanup()
            if not passed then row.status="Error";row.error=tostring(failure)end
            report.elapsed=os.clock()-started;save()
        end
    end
end)
cleanup();loader:close();cache:close();folder:Destroy()
if not ok then report.error=tostring(message)end
report.complete=ok and #report.results==#targets*#modes
report.controlsPassed=true
for _,row in ipairs(report.results)do if row.control and row.status~="PoseChangesObserved"then report.controlsPassed=false end end
report.conclusive=report.complete and report.controlsPassed
report.elapsed=os.clock()-started;save()
print("Fruit playback comparison saved: "..output.." | complete="..tostring(report.complete).." | controls="..tostring(report.controlsPassed))
return report
