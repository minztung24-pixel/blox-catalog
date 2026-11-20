-- Read currently held fruit rigs/tracks/assets. No playback, inventory writes or property changes.
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local Content=game:GetService("ContentProvider")
local detailed=(...=="visuals")
local player=assert(Players.LocalPlayer,"Run on the client")
assert(typeof(writefile)=="function","Run in Potassium")
local started=os.clock()
local output=(detailed and "blox-fruits-held-visuals-" or "blox-fruits-fruit-runtime-")..game.PlaceId..".json"
local report={schemaVersion=detailed and 2 or 1,placeId=game.PlaceId,gameId=game.GameId,complete=false,fruits={},logs={}}
local wanted,completed={["1525"]=true,["1422"]=true,["1391"]=true},{}
local seen,knownIds,connections={},{},{}
local function pathOf(node,root)
    local names={}
    while node and node~=root do table.insert(names,1,node.Name);node=node.Parent end
    return table.concat(names,"/")
end
local function register(tool)
    if not tool:IsA("Tool") or seen[tool] or #report.fruits>=6 then return end
    if not (tool:GetAttribute("BloxCatalogOwned") and tool.ToolTip=="Fruits") and not tool.Name:match(" Fruit$") then return end
    local row={name=tool.Name,itemId=tool:GetAttribute("ItemId"),localVisual=tool:GetAttribute("BloxCatalogOwned")==true,
        elapsed=os.clock()-started,animations={},samples={}}
    for _,node in ipairs(tool:GetDescendants()) do
        if node:IsA("Animation") then
            table.insert(row.animations,{path=pathOf(node,tool),id=node.AnimationId})
            local id=node.AnimationId:match("%d+");if id then knownIds[id]=true end
        end
    end
    seen[tool]={row=row,started=os.clock(),next=1}
    table.insert(report.fruits,row)
end
local function fetch(asset)
    if asset=="" then return nil end
    local ok,value=pcall(Content.GetAssetFetchStatus,Content,asset)
    return {id=asset,status=ok and tostring(value) or nil,error=not ok and tostring(value) or nil}
end
local function sample(tool,row)
    local data={elapsed=os.clock()-started,held=tool.Parent==player.Character,tracks={},poses={},effects={},meshes={}}
    if data.held then
        local handle=tool:FindFirstChild("Handle")
        local camera=workspace.CurrentCamera
        if detailed then
            data.animationStatus=tool:GetAttribute("BloxCatalogAnimationStatus")
            data.animationError=tool:GetAttribute("BloxCatalogAnimationError")
            data.handle=handle and handle:IsA("BasePart") and {handle.CFrame:GetComponents()} or nil
            data.camera=camera and {camera.CFrame:GetComponents()} or nil
        end
        local function position(frame)
            if not detailed or not frame then return nil end
            local relative=handle and handle:IsA("BasePart") and handle.CFrame:ToObjectSpace(frame)
            return {world={frame:GetComponents()},relative=relative and {relative:GetComponents()} or nil,
                distanceFromHandle=handle and handle:IsA("BasePart") and (frame.Position-handle.Position).Magnitude or nil}
        end
        for _,node in ipairs(tool:GetDescendants()) do
            if node:IsA("Animator") then
                local ok,tracks=pcall(node.GetPlayingAnimationTracks,node)
                if ok then for _,track in ipairs(tracks) do
                    table.insert(data.tracks,{animator=pathOf(node,tool),id=track.Animation and track.Animation.AnimationId,
                        length=track.Length,playing=track.IsPlaying,timePosition=track.TimePosition,speed=track.Speed,weight=track.WeightCurrent})
                end else data.trackReadError=tostring(tracks) end
            elseif (node:IsA("Motor6D") or node:IsA("Bone") or detailed and node:IsA("Weld")) and #data.poses<(detailed and 300 or 24) then
                local pose={path=pathOf(node,tool),class=node.ClassName}
                if node:IsA("Motor6D") or node:IsA("Bone")then pose.transform={node.Transform:GetComponents()}end
                if detailed then
                    if node:IsA("Bone")then pose.position=position(node.TransformedWorldCFrame);pose.rest={node.CFrame:GetComponents()}
                    else
                        pose.c0={node.C0:GetComponents()};pose.c1={node.C1:GetComponents()}
                        pose.part0=node.Part0 and pathOf(node.Part0,tool);pose.part1=node.Part1 and pathOf(node.Part1,tool)
                    end
                end
                table.insert(data.poses,pose)
            elseif node:IsA("ParticleEmitter") then
                local effect={path=pathOf(node,tool),enabled=node.Enabled,rate=node.Rate,timeScale=node.TimeScale,texture=fetch(node.Texture)}
                if detailed then
                    effect.lifetime={node.Lifetime.Min,node.Lifetime.Max};effect.speed={node.Speed.Min,node.Speed.Max}
                    effect.size=tostring(node.Size);effect.transparency=tostring(node.Transparency)
                    effect.emitCount=node:GetAttribute("EmitCount");effect.emitDelay=node:GetAttribute("EmitDelay")
                    local parent=node.Parent
                    local frame=parent:IsA("Bone") and parent.TransformedWorldCFrame or parent:IsA("Attachment") and parent.WorldCFrame
                        or parent:IsA("BasePart") and parent.CFrame
                    effect.position=position(frame)
                end
                table.insert(data.effects,effect)
            elseif node:IsA("MeshPart") and #data.meshes<24 then
                local mesh={path=pathOf(node,tool),mesh=fetch(node.MeshId),texture=fetch(node.TextureID)}
                if detailed then
                    mesh.position=position(node.CFrame);mesh.size={node.Size.X,node.Size.Y,node.Size.Z}
                    mesh.transparency=node.Transparency;mesh.localTransparency=node.LocalTransparencyModifier
                    mesh.material=tostring(node.Material);mesh.color={node.Color.R,node.Color.G,node.Color.B}
                    local appearance=node:FindFirstChildOfClass("SurfaceAppearance")
                    if appearance then mesh.colorMap=fetch(appearance.ColorMap)end
                end
                table.insert(data.meshes,mesh)
            end
        end
    end
    table.insert(row.samples,data)
end
local character=assert(player.Character,"Wait for your character")
for _,tool in ipairs(character:GetChildren()) do register(tool) end
table.insert(connections,character.ChildAdded:Connect(register))
table.insert(connections,game:GetService("LogService").MessageOut:Connect(function(message,kind)
    if #report.logs>=30 or not message:lower():find("anim",1,true) then return end
    for id in pairs(knownIds) do
        if message:find(id,1,true) then
            table.insert(report.logs,{elapsed=os.clock()-started,kind=tostring(kind),message=message:sub(1,700)});break
        end
    end
end))
print(detailed and "Held visual observer ready: Equip Arcsteel, Gas, Magma; giu moi trai 8 giay. Chi doc, khong Eat/Drop/Store."
    or "Fruit runtime observer ready: trong 40 giay, cam Arcsteel va mot trai bi loi, moi trai giu it nhat 6 giay.")
local checkpoints=detailed and {0.2,1,3,6} or {0.2,1,3,5}
local ok,failure=pcall(function()
while os.clock()-started<(detailed and 90 or 40) and player.Character==character do
    for _,tool in ipairs(character:GetChildren()) do register(tool) end
    for tool,record in pairs(seen) do
        local due=checkpoints[record.next]
        if due and os.clock()-record.started>=due then
            sample(tool,record.row);record.next+=1
            if record.next>#checkpoints and record.row.samples[#record.row.samples].held then completed[tostring(record.row.itemId)]=true end
        end
    end
    writefile(output,Http:JSONEncode(report))
    if detailed and completed["1525"] and completed["1422"] and completed["1391"]then break end
    task.wait(0.2)
end
end)
for _,connection in ipairs(connections) do connection:Disconnect() end
report.complete=ok and player.Character==character
if not ok then report.error=tostring(failure)end
if detailed then
    report.targetsComplete=true
    for id in pairs(wanted)do if not completed[id]then report.targetsComplete=false end end
end
writefile(output,Http:JSONEncode(report))
print("Fruit runtime report saved: "..output.." | fruits="..#report.fruits)
return report
