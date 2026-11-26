-- Inspect local fruit files and available player Tools. Measure motion on private copies.
assert(game.GameId==994732206,"Run in Blox Fruits")
assert(type(readfile)=="function" and type(writefile)=="function","Run in Potassium")
local Http=game:GetService("HttpService")
local Content=game:GetService("ContentProvider")
local player=assert(game:GetService("Players").LocalPlayer,"Run on the client")
local source=readfile("blox-catalog-sim-v12.6.lua")
local replacements
source,replacements=source:gsub("return UI%.start%(%)%s*$",
    "return {Catalog=Catalog,Equipment=Equipment,FruitModels=FruitModels}")
assert(replacements==1,"Expected the standalone client")
local modules=assert(loadstring(source,"FruitAndSkinAudit"))()
local models=modules.FruitModels.new()
local loader=modules.Equipment.animationLoader(nil,5)
local folder=Instance.new("Folder");folder.Name="BloxCatalogFruitSkinAudit"
local report={schemaVersion=1,placeId=game.PlaceId,gameId=game.GameId,complete=false,
    scope="Local files and current player Tools; private-copy rig motion, render fetch status and authored VFX",
    categories={Fruits={},["Fruit Skins"]={}},files={}}
local output="blox-catalog-fruit-skin-audit-"..game.PlaceId..".json"
local targets={}
for _,category in ipairs({"Fruits","Fruit Skins"})do
    for _,item in ipairs(modules.Catalog.search("",category))do
        local row={id=item.id,name=item.name,category=category,idType=item.idType,
            physical=item.isPhysicalFruit==true,skinId=item.skinId,baseFruitId=item.baseFruitId,status="Pending"}
        table.insert(report.categories[category],row)
        table.insert(targets,{item=item,row=row})
    end
end
assert(#targets>0 and #targets<=160,"Unexpected target count")
if type(listfiles)=="function"then
    local ok,files=pcall(listfiles,"codex_fruit_studio/models")
    if ok then for _,file in ipairs(files)do
        local name=file:gsub("\\","/"):match("([^/]+%.rbxm)$")
        if name then table.insert(report.files,name)end
    end end
end
local activeTool,activeMotion,activeFetch
local activeImages={}
local function cleanup()
    if activeFetch then pcall(task.cancel,activeFetch);activeFetch=nil end
    for _,image in ipairs(activeImages)do image:Destroy()end
    table.clear(activeImages)
    if activeMotion then activeMotion:close();activeMotion=nil end
    if activeTool then activeTool:Destroy();activeTool=nil end
end
local function inspect(target)
    local item,row=target.item,target.row
    if not item.isPhysicalFruit then row.status="MetadataOnly";return end
    row.path=models:path(item)
    local native=modules.Equipment.findExistingTool(player,item)
    if native then models:capture(item,native)end
    row.nativeToolAvailable=native~=nil
    local template,reason=models:load(item)
    if not template then
        row.status=row.path and "ModelRejected" or "MissingModel"
        row.error=tostring(reason);return
    end
    row.status="ModelLoaded"
    activeTool=assert(modules.Equipment.clone(template,item),"Could not clone model")
    local tool=activeTool
    row.hasHandle=tool:FindFirstChild("Handle")~=nil
    row.meshes={};row.animations={};row.effects={};row.assets={}
    local nodes,seenAssets={},{}
    local function asset(id,property,path)
        if type(id)~="string" or id==""then return end
        table.insert(row.assets,{id=id,property=property,path=path,status=tostring(Content:GetAssetFetchStatus(id))})
    end
    local joints={}
    for _,node in ipairs(tool:GetDescendants())do
        local path=node:GetFullName():sub(#tool:GetFullName()+2)
        if node:IsA("BasePart")then
            if node:IsA("MeshPart")then
                table.insert(row.meshes,{path=path,mesh=node.MeshId,texture=node.TextureID})
                asset(node.MeshId,"MeshId",path);asset(node.TextureID,"TextureID",path)
                table.insert(nodes,node)
            end
        elseif node:IsA("SurfaceAppearance")then
            for _,property in ipairs({"ColorMap","NormalMap","RoughnessMap","MetalnessMap"})do
                local id=node[property];asset(id,property,path)
                if id~="" and not seenAssets[id]then
                    seenAssets[id]=true
                    local image=Instance.new("ImageLabel");image.Image=id
                    table.insert(activeImages,image);table.insert(nodes,image)
                end
            end
        elseif node:IsA("ParticleEmitter") or node:IsA("Beam") or node:IsA("Trail")then
            table.insert(row.effects,{path=path,class=node.ClassName,enabled=node.Enabled,texture=node.Texture,
                rate=node:IsA("ParticleEmitter") and node.Rate or nil,emitCount=node:GetAttribute("EmitCount"),
                timeScale=node:IsA("ParticleEmitter") and node.TimeScale or nil})
            asset(node.Texture,"VFX Texture",path);table.insert(nodes,node)
        elseif node:IsA("Animation")then
            table.insert(row.animations,{path=path,id=node.AnimationId})
        elseif node:IsA("Bone") or node:IsA("Motor6D") or node:IsA("AnimationConstraint")then
            table.insert(joints,node)
        end
    end
    local finished=#nodes==0
    local fetchError
    local worker
    if not finished then worker=task.spawn(function()
        local ok,err=pcall(Content.PreloadAsync,Content,nodes)
        if not ok then fetchError=tostring(err)end
        finished=true
    end);activeFetch=worker end
    local deadline=os.clock()+6
    while not finished and os.clock()<deadline do task.wait(.05)end
    if not finished then pcall(task.cancel,worker);fetchError="Render preload timed out" end
    activeFetch=nil
    row.renderFetchComplete=finished;row.renderFetchError=fetchError
    for _,record in ipairs(row.assets)do record.status=tostring(Content:GetAssetFetchStatus(record.id))end
    for _,image in ipairs(activeImages)do image:Destroy()end
    table.clear(activeImages)
    row.joints=#joints;row.movingJoints=0
    for _,node in ipairs(tool:GetDescendants())do
        if node:IsA("BasePart")then
            node.Transparency=1;node.Anchored=node==tool.Handle
            node.CanCollide=false;node.CanTouch=false;node.CanQuery=false
        elseif node:IsA("ParticleEmitter") or node:IsA("Beam") or node:IsA("Trail") or node:IsA("Light")then
            node.Enabled=false
        end
    end
    tool.Handle.CFrame=workspace.CurrentCamera.CFrame*CFrame.new(0,0,-12)
    tool.Parent=folder
    activeMotion=modules.Equipment.fruitMotion(tool,function()end,function(animator,animation)
        pcall(function()animator.PreferLodEnabled=false end)
        return loader:load(animator,animation)
    end,5)
    activeMotion:setActive(true)
    deadline=os.clock()+7
    while tool:GetAttribute("BloxCatalogAnimationStatus")=="Loading" and os.clock()<deadline do task.wait(.05)end
    row.animationStatus=tool:GetAttribute("BloxCatalogAnimationStatus")
    row.animationError=tool:GetAttribute("BloxCatalogAnimationError")
    if row.animationStatus~="Ready"then return end
    local tracks={}
    for _,node in ipairs(tool:GetDescendants())do
        if node:IsA("Animator")then
            for _,track in ipairs(node:GetPlayingAnimationTracks())do table.insert(tracks,track)end
        end
    end
    local previous,moved={},{}
    for phase=0,5 do
        for _,track in ipairs(tracks)do track:AdjustSpeed(0);track.TimePosition=track.Length*phase/6 end
        task.wait(.1)
        for _,joint in ipairs(joints)do
            local pose=joint.Transform
            if previous[joint] and not moved[joint] and not previous[joint]:FuzzyEq(pose,.00001)then
                moved[joint]=true;row.movingJoints+=1
            end
            previous[joint]=pose
        end
    end
    row.motionStatus=row.movingJoints>0 and "PoseChangesObserved" or "NoPoseChangesObserved"
end
print("Fruit / Skin audit started. Tu dong kiem tra hai nhom, khong can Equip hay tha trai.")
local started=os.clock()
local ok,failure=pcall(function()
    assert(workspace.CurrentCamera,"Wait for the camera")
    folder.Parent=workspace
    for index,target in ipairs(targets)do
        if os.clock()-started>900 then report.limited=true;break end
        local success,message=pcall(inspect,target)
        cleanup()
        if not success then target.row.status="Error";target.row.error=tostring(message)end
        report.processed=index
        writefile(output,Http:JSONEncode(report))
        task.wait()
    end
end)
cleanup();loader:close();models:close();folder:Destroy()
if not ok then report.error=tostring(failure)end
report.complete=ok and not report.limited and report.processed==#targets
report.elapsed=os.clock()-started
writefile(output,Http:JSONEncode(report))
print("Fruit / Skin audit saved: "..output.." | complete="..tostring(report.complete))
return report
