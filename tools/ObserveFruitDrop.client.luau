-- Observe a manual real-fruit Drop. No remote calls, property writes, pickup or menu actions.
local player=game:GetService("Players").LocalPlayer
assert(player,"Run on the client")
assert(typeof(writefile)=="function","Run in Potassium")
print("Drop observer v2: dang cho cam trai vat pham, bam o hotbar cua trai (vi du phim 4). Toi da 90 giay.")
local tool
local readyDeadline=os.clock()+90
repeat
    local character=player.Character
    if character then
        for _,candidate in ipairs(character:GetChildren()) do
            if candidate:IsA("Tool") and not candidate:GetAttribute("BloxCatalogOwned")
                and not candidate:GetAttribute("ClientCatalogOwned") and candidate.Name:match(" Fruit$") then
                local handle=candidate:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then tool=candidate;break end
            end
        end
    end
    if not tool then task.wait(.2) end
until tool or os.clock()>=readyDeadline
if not tool then
    warn("Drop observer v2: chua thay trai vat pham tren tay sau 90 giay. Hay bam o hotbar cua trai roi chay lai.")
    return nil
end
local filename="blox-fruits-real-drop-v2-"..game.PlaceId..".json"
local started=os.clock()
local report={schemaVersion=2,placeId=game.PlaceId,gameId=game.GameId,fruit=tool.Name,samples={}}
local tracked=tool
local function frame(value)return {value:GetComponents()}end
local function vector(value)return {value.X,value.Y,value.Z}end
local function parentKind(object)
    if object.Parent==player.Character then return "Character" end
    if object.Parent==player:FindFirstChildOfClass("Backpack") then return "Backpack" end
    if object:IsDescendantOf(workspace) then return "Workspace" end
    return object.Parent and object.Parent.ClassName or "Removed"
end
local function inspect(object)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local row={name=object.Name,sameInstance=object==tool,parent=parentKind(object),parts={},interactions={},joints={}}
    row.requiresHandle=object.RequiresHandle;row.canBeDropped=object.CanBeDropped;row.grip=frame(object.Grip)
    row.itemId=object:GetAttribute("ItemId")
    local handle=object:FindFirstChild("Handle")
    local function path(node)
        if not node then return nil end
        if not node:IsDescendantOf(object) then return "external:"..node.Name end
        local names={}
        while node and node~=object do table.insert(names,1,node.Name);node=node.Parent end
        return table.concat(names,"/")
    end
    for index,node in ipairs(object:GetDescendants()) do
        if index>300 then row.truncated=true;break end
        if node:IsA("BasePart") then
            table.insert(row.parts,{path=path(node),class=node.ClassName,size=vector(node.Size),anchored=node.Anchored,
                collide=node.CanCollide,touch=node.CanTouch,query=node.CanQuery,massless=node.Massless,collisionGroup=node.CollisionGroup,
                relative=root and frame(root.CFrame:ToObjectSpace(node.CFrame)),linear=vector(node.AssemblyLinearVelocity),angular=vector(node.AssemblyAngularVelocity)})
        elseif node:IsA("TouchTransmitter") or node:IsA("ProximityPrompt") or node:IsA("ClickDetector") then
            table.insert(row.interactions,{path=path(node),class=node.ClassName})
        end
    end
    if handle and handle:IsA("BasePart") then
        for _,joint in ipairs(handle:GetJoints()) do
            table.insert(row.joints,{name=joint.Name,class=joint.ClassName,part0=path(joint.Part0),part1=path(joint.Part1)})
        end
    end
    return row
end
local function snapshot(reason)
    local sample={reason=reason,elapsed=os.clock()-started,original=inspect(tool),tracked=inspect(tracked),nearby={}}
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    for _,candidate in ipairs(workspace:GetChildren()) do
        if #sample.nearby>=3 then break end
        if candidate:IsA("Tool") and candidate.Name==tool.Name and not candidate:GetAttribute("BloxCatalogOwned") then
            local handle=candidate:FindFirstChild("Handle")
            if root and handle and handle:IsA("BasePart") and (handle.Position-root.Position).Magnitude<20 then
                table.insert(sample.nearby,inspect(candidate))
            end
        end
    end
    table.insert(report.samples,sample)
    writefile(filename,game:GetService("HttpService"):JSONEncode(report))
end
snapshot("held")
print("Drop observer ready: trong 60 giay, dung menu game tha trai that, doi 2 giay roi nhat lai. Script chi quan sat.")
local previous=parentKind(tool)
local droppedAt,nextWorldSample,worldSamples=nil,nil,0
while os.clock()-started<60 do
    task.wait(0.1)
    if parentKind(tracked)=="Removed" then
        local matches={}
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        for _,container in pairs({workspace,droppedAt and player:FindFirstChildOfClass("Backpack"),droppedAt and player.Character}) do
            if container then for _,candidate in ipairs(container:GetChildren()) do
                local handle=candidate:IsA("Tool") and candidate:FindFirstChild("Handle")
                if candidate.Name==tool.Name and not candidate:GetAttribute("BloxCatalogOwned") and handle and root
                    and handle:IsA("BasePart") and (handle.Position-root.Position).Magnitude<20 then table.insert(matches,candidate) end
            end end
        end
        if #matches==1 then tracked=matches[1];report.replacementObserved=true end
    end
    local current=parentKind(tracked)
    if current~=previous then
        snapshot("parent changed: "..current)
        previous=current
        if current=="Workspace" and not droppedAt then droppedAt=os.clock();nextWorldSample=droppedAt+0.5 end
        if droppedAt and (current=="Backpack" or current=="Character") then report.pickupObserved=true;break end
    end
    if droppedAt and current=="Workspace" and worldSamples<3 and os.clock()>=nextWorldSample then
        snapshot("dropped physics");worldSamples+=1;nextWorldSample=os.clock()+0.6
    end
end
report.dropObserved=droppedAt~=nil
snapshot("finish")
print("Real drop report saved: "..filename.." | drop="..tostring(report.dropObserved).." | pickup="..tostring(report.pickupObserved==true))
return report
