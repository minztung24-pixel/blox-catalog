-- Read-only settled/drop observations. No property writes, remotes, pickup or drop actions.
assert(game.GameId==994732206 and type(writefile)=="function","Run in Blox Fruits with Potassium")
local player=game:GetService("Players").LocalPlayer
local mode=...
local output=(mode=="handles"and "blox-catalog-drop-handles-"or "blox-catalog-dropped-fruit-")..game.PlaceId..".json"
local report={schemaVersion=1,placeId=game.PlaceId,samples={},complete=false}
report.inventory={}
local tracked={}
for _,root in pairs({player:FindFirstChildOfClass("Backpack"),player.Character})do for _,tool in ipairs(root:GetChildren())do
    if tool:IsA("Tool")then
        tracked[tool]=true
        local handle=tool:FindFirstChild("Handle")
        table.insert(report.inventory,{name=tool.Name,tooltip=tool.ToolTip,owned=tool:GetAttribute("BloxCatalogOwned"),itemId=tool:GetAttribute("ItemId"),
            handle=handle~=nil,handleSize=handle and {handle.Size.X,handle.Size.Y,handle.Size.Z},parent=root.ClassName})
    end
end end
local function vector(v)return {v.X,v.Y,v.Z}end
local function frame(v)return {v:GetComponents()}end
local function snapshot()
    local character=player.Character
    local origin=character and character:FindFirstChild("HumanoidRootPart")
    local sample={time=os.clock(),fruits={}}
    if not origin then return end
    local candidates=workspace:GetChildren()
    local added={};for _,tool in ipairs(candidates)do added[tool]=true end
    for tool in pairs(tracked)do if tool.Parent and (tool:IsDescendantOf(workspace)or mode=="handles")and not added[tool]then table.insert(candidates,tool);added[tool]=true end end
    if character then for _,tool in ipairs(character:GetChildren())do if tool:IsA("Tool")and not added[tool]then table.insert(candidates,tool);added[tool]=true;tracked[tool]=true end end end
    for _,tool in ipairs(candidates)do
        local handle=tool:IsA("Tool")and (tool:FindFirstChild("Handle")or tool:FindFirstChildWhichIsA("BasePart",true))
        if handle and handle:IsA("BasePart")and (handle.Position-origin.Position).Magnitude<65 and #sample.fruits<12 then
            local filter=RaycastParams.new()
            filter.FilterType=Enum.RaycastFilterType.Exclude;filter.FilterDescendantsInstances={tool,character};filter.RespectCanCollide=true
            local hit=workspace:Raycast(handle.Position+Vector3.new(0,5,0),Vector3.new(0,-40,0),filter)
            local row={name=tool.Name,itemId=tool:GetAttribute("ItemId"),owned=tool:GetAttribute("BloxCatalogOwned")==true,phase=tool.Parent==character and "Held"or tool.Parent==workspace and "World"or "Other",
                handle=frame(handle.CFrame),ground=hit and vector(hit.Position),groundPart=hit and hit.Instance:GetFullName(),parts={},bones={},tags=game:GetService("CollectionService"):GetTags(tool)}
            for _,node in ipairs(tool:GetDescendants())do
                if node:IsA("BasePart")and #row.parts<60 then
                    table.insert(row.parts,{name=node.Name,size=vector(node.Size),relative=frame(handle.CFrame:ToObjectSpace(node.CFrame)),
                        transparency=node.Transparency,anchored=node.Anchored,collide=node.CanCollide,touch=node.CanTouch,massless=node.Massless,
                        linear=vector(node.AssemblyLinearVelocity),angular=vector(node.AssemblyAngularVelocity),class=node.ClassName})
                elseif node:IsA("Bone")and #row.bones<12 then
                    table.insert(row.bones,{name=node.Name,transform=frame(node.Transform)})
                end
            end
            table.insert(sample.fruits,row)
        end
    end
    table.insert(report.samples,sample)
    writefile(output,game:GetService("HttpService"):JSONEncode(report))
end
print("Drop geometry observer ready: 10 minutes; only reading Tools and the floor")
for _=1,mode=="handles"and 1 or 1200 do snapshot();task.wait(.5)end
report.complete=true
writefile(output,game:GetService("HttpService"):JSONEncode(report))
print("Dropped fruit scene saved | samples="..#report.samples)
return report
