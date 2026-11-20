-- Test candidate clips on hidden, sanitized copies. Never equip or edit a player's Tool.
assert(game.GameId==994732206,"Run in the original Blox Fruits experience")
local Http=game:GetService("HttpService")
local manifestFile=... or "codex-original-fruit-animation-candidates.json"
local manifest=Http:JSONDecode(readfile(manifestFile))
assert(manifest.schemaVersion==1 and manifest.gameId==game.GameId and #manifest.targets<=50,"Invalid candidate manifest")
local source=readfile(manifest.verifyImports and "blox-catalog-sim-v12.lua" or "blox-catalog-sim-v11.lua")
local replacements
source,replacements=source:gsub("return UI%.start%(%)%s*$","return {Equipment=Equipment,FruitModels=FruitModels,Catalog=Catalog}")
assert(replacements==1,"Expected the standalone client; no UI was started")
local modules=assert(loadstring(source,"FruitReferenceModules"))()
local models=modules.FruitModels.new()
local loader=modules.Equipment.animationLoader(nil,6)
local report={schemaVersion=1,gameId=game.GameId,placeId=game.PlaceId,source=manifest.source,
    complete=false,conclusive=false,results={},verified={}}
local output=(manifest.verifyImports and "blox-fruits-v12-animation-validation-" or "blox-fruits-original-animation-rigs-")..game.PlaceId..".json"
local folder=Instance.new("Folder");folder.Name="BloxCatalogAnimationReferenceProbe"
local started=os.clock()
local currentMotion,currentTool
local function relative(node,root)
    if not node then return "<nil>" end
    local parts={}
    while node and node~=root do table.insert(parts,1,node.Name);node=node.Parent end
    return node==root and table.concat(parts,"/") or "<external>"
end
local function signature(root)
    local lines={}
    for _,node in ipairs(root:GetDescendants())do
        if node:IsA("BasePart") or node:IsA("Bone") or node:IsA("Motor6D") or node:IsA("AnimationController")then
            local row=node.ClassName..":"..relative(node,root)
            if node:IsA("MeshPart")then row=row..":"..node.MeshId end
            if node:IsA("Motor6D")then row=row..":"..relative(node.Part0,root)..":"..relative(node.Part1,root) end
            table.insert(lines,row)
        end
    end
    table.sort(lines)
    local text=table.concat(lines,"\n")
    local hash=2166136261
    for i=1,#text do
        hash=bit32.bxor(hash,text:byte(i))
        hash=(hash*403+bit32.lshift(hash,24))%4294967296
    end
    return string.format("%08x:%d",hash,#lines)
end
local function changed(a,b)
    local x,y={a:GetComponents()},{b:GetComponents()}
    for i=1,12 do if math.abs(x[i]-y[i])>0.00001 then return true end end
    return false
end
assert(not changed(CFrame.new(),CFrame.new()) and changed(CFrame.new(),CFrame.new(.1,0,0)),"Motion detector self-check failed")
local function cleanupCurrent()
    if currentMotion then currentMotion:close();currentMotion=nil end
    if currentTool then currentTool:Destroy();currentTool=nil end
end
local function test(target)
    assert(type(target.itemId)=="string" and target.itemId:match("^%d+$") and type(target.animationId)=="string"
        and target.animationId:match("^rbxassetid://%d+$"),"Invalid candidate ID")
    local item=modules.Catalog.byId[target.itemId]
    assert(item and item.category=="Fruits" and item.name==target.name,"Candidate does not match catalog")
    local row={itemId=item.id,name=item.name,animationId=target.animationId,control=target.control==true,file=models:path(item)}
    local template,message=models:load(item)
    if not template then row.status="MissingModel";row.error=tostring(message);return row end
    currentTool=assert(modules.Equipment.clone(template,item),"Could not clone the sanitized model")
    local tool=currentTool
    row.signature=signature(tool)
    local fruit=tool:FindFirstChild("Fruit")
    local controller=fruit and fruit:FindFirstChildOfClass("AnimationController")
    if not controller then row.status="MissingRig";return row end
    local animation=fruit:FindFirstChild("Idle") or fruit:FindFirstChild("Animation")
    if animation and not animation:IsA("Animation")then row.status="InvalidRig";return row end
    row.originalId=animation and animation.AnimationId or ""
    if not animation then animation=Instance.new("Animation",fruit);animation.Name="Idle" end
    if manifest.verifyImports then
        assert(animation.AnimationId==target.animationId,"Imported model still has the wrong animation ID")
    else animation.AnimationId=target.animationId end
    local joints={}
    for _,node in ipairs(tool:GetDescendants())do
        if node:IsA("BasePart")then node.Transparency=1;node.Anchored=node==tool.Handle;node.CanCollide=false
        elseif node:IsA("ParticleEmitter") or node:IsA("Beam") or node:IsA("Trail")then node.Enabled=false
        elseif node:IsA("Bone") or node:IsA("Motor6D")then table.insert(joints,node) end
    end
    row.joints=#joints
    tool.Handle.CFrame=workspace.CurrentCamera.CFrame*CFrame.new(0,0,-12)
    tool.Parent=folder
    currentMotion=modules.Equipment.fruitMotion(tool,function()end,function(animator,actual)
        pcall(function()animator.PreferLodEnabled=false end)
        return loader:load(animator,actual)
    end,6)
    currentMotion:setActive(true)
    local deadline=os.clock()+13
    repeat task.wait(.05)until tool:GetAttribute("BloxCatalogAnimationStatus")~="Loading" or os.clock()>deadline
    row.loadStatus=tool:GetAttribute("BloxCatalogAnimationStatus")
    if row.loadStatus~="Ready" then
        row.status="LoadFailed";row.error=tool:GetAttribute("BloxCatalogAnimationError") or "Load deadline reached";return row
    end
    local animator=controller:FindFirstChildOfClass("Animator")
    local tracks=animator:GetPlayingAnimationTracks()
    local track=assert(tracks[1],"Ready state has no playing track")
    row.length=track.Length
    local previous,moved={},{}
    for index=1,6 do
        track.TimePosition=track.Length*(index-1)/6
        task.wait(.1)
        for _,node in ipairs(joints)do
            local value=node.Transform
            if previous[node] and changed(previous[node],value)then moved[relative(node,tool)]=true end
            previous[node]=value
        end
    end
    row.movingNodes=0;row.examples={}
    for path in pairs(moved)do row.movingNodes+=1;if #row.examples<8 then table.insert(row.examples,path) end end
    row.status=row.movingNodes>0 and "Moved" or "NoRigMotion"
    return row
end
local ok,failure=pcall(function()
    assert(workspace.CurrentCamera,"Wait for the game camera")
    folder.Parent=workspace
    for index,target in ipairs(manifest.targets)do
        if os.clock()-started>150 then report.limited=true;break end
        print("Original fruit rig check "..index.."/"..#manifest.targets..": "..target.name)
        local passed,row=pcall(test,target)
        cleanupCurrent()
        if not passed then row={itemId=target.itemId,name=target.name,control=target.control==true,status="Error",error=tostring(row)} end
        table.insert(report.results,row)
        writefile(output,Http:JSONEncode(report))
        task.wait()
    end
end)
cleanupCurrent();loader:close();models:close();folder:Destroy()
if not ok then report.error=tostring(failure) end
report.complete=ok and not report.limited and #report.results==#manifest.targets
local controlCount,loadedControls,movingControls=0,0,0
for _,row in ipairs(report.results)do
    if row.control then
        controlCount+=1
        if row.loadStatus=="Ready" then loadedControls+=1 end
        if row.status=="Moved" then movingControls+=1 end
    end
end
report.controls={tested=controlCount,loaded=loadedControls,moved=movingControls}
report.conclusive=report.complete and controlCount==3 and loadedControls==3 and movingControls>0
if report.conclusive then
    for _,row in ipairs(report.results)do
        if not row.control and row.status=="Moved" and row.originalId~=row.animationId then
            table.insert(report.verified,{itemId=row.itemId,name=row.name,originalId=row.originalId,
                animationId=row.animationId,signature=row.signature,movingNodes=row.movingNodes})
        end
    end
end
writefile(output,Http:JSONEncode(report))
print("Original fruit rig report saved: "..output.." | verified="..#report.verified.." | conclusive="..tostring(report.conclusive))
return report
