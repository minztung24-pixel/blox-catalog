-- Read-only current-client evidence. Never require modules, load assets, equip, or invoke remotes.
assert(game.GameId==994732206,"Run in the original Blox Fruits experience")
local Http=game:GetService("HttpService")
local Content=game:GetService("ContentProvider")
local player=assert(game:GetService("Players").LocalPlayer,"Run on the client")
local report={schemaVersion=1,gameId=game.GameId,placeId=game.PlaceId,placeVersion=game.PlaceVersion,
    complete=false,sources={},modules={},localTools={},roots={}}
local gui=player.PlayerGui:FindFirstChild("BloxCatalogSim")
report.catalogVersion=gui and gui:GetAttribute("Version")
local wanted={control=true,dragon=true,ember=true,empyrean=true,galaxy=true,gas=true,flame=true,
    kitsune=true,lightning=true,magma=true,mammoth=true,meme=true,pain=true,phoenix=true,
    quake=true,rocket=true,rubber=true,spider=true,spirit=true,werewolf=true,tiger=true,spring=true}
local function relevant(name)
    name=name:lower()
    for word in pairs(wanted)do if name:find(word,1,true)then return true end end
    return false
end
assert(relevant("Gas Fruit") and not relevant("Unrelated"),"Source filter self-check failed")
local function asset(id)
    if not id or id==""then return nil end
    local ok,status=pcall(Content.GetAssetFetchStatus,Content,id)
    return {id=id,status=ok and tostring(status) or nil,error=not ok and tostring(status) or nil}
end
local function inspect(tool)
    local row={name=tool.Name,path=tool:GetFullName(),class=tool.ClassName,itemId=tool:GetAttribute("ItemId"),
        originalName=tool:GetAttribute("OriginalName"),catalogOwned=tool:GetAttribute("BloxCatalogOwned")==true,
        tags=tool:GetTags(),parts={},animations={},effects={},scripts={},surfaces={}}
    local nodes=tool:GetDescendants()
    row.nodes=#nodes
    if #nodes>3000 then row.limited=true;return row end
    for _,node in ipairs(nodes)do
        local path=node:GetFullName():sub(#row.path+2)
        if node:IsA("MeshPart")then
            table.insert(row.parts,{path=path,mesh=asset(node.MeshId),texture=asset(node.TextureID),
                transparency=node.Transparency,localTransparency=node.LocalTransparencyModifier})
        elseif node:IsA("Decal") or node:IsA("Texture")then
            table.insert(row.surfaces,{path=path,class=node.ClassName,texture=asset(node.Texture),transparency=node.Transparency,face=node.Face.Name})
        elseif node:IsA("SurfaceAppearance")then
            table.insert(row.surfaces,{path=path,class=node.ClassName,colorMap=asset(node.ColorMap),alphaMode=node.AlphaMode.Name})
        elseif node:IsA("ParticleEmitter")then
            table.insert(row.effects,{path=path,class=node.ClassName,texture=asset(node.Texture),enabled=node.Enabled,rate=node.Rate})
        elseif node:IsA("Beam") or node:IsA("Trail")then
            table.insert(row.effects,{path=path,class=node.ClassName,texture=asset(node.Texture),enabled=node.Enabled})
        elseif node:IsA("Animation")then table.insert(row.animations,{path=path,id=node.AnimationId})
        elseif node:IsA("LuaSourceContainer")then table.insert(row.scripts,{path=path,class=node.ClassName,enabled=node:IsA("BaseScript") and node.Enabled or nil}) end
    end
    return row
end
local output="blox-fruits-current-source-audit-"..game.PlaceId..".json"
local seen={}
for _,root in pairs({player.Character,player:FindFirstChildOfClass("Backpack")})do
    for _,tool in ipairs(root:GetChildren())do
        if tool:IsA("Tool")then table.insert(report.localTools,inspect(tool));seen[tool]=true end
    end
end
local scanned=0
local storage=game:GetService("ReplicatedStorage")
local roots={workspace}
for _,name in ipairs({"Storage","ControlStorage","Assets","WorldModel"})do
    local root=storage:FindFirstChild(name)
    if root then table.insert(roots,root)end
end
table.insert(roots,storage)
local visited={}
for _,root in ipairs(roots)do
    local children={}
    for _,child in ipairs(root:GetChildren())do
        table.insert(children,{name=child.Name,class=child.ClassName})
        if not seen[child] and #report.sources<80 and child:IsA("Tool") and relevant(child.Name)then
            seen[child]=true;table.insert(report.sources,inspect(child))
        end
    end
    table.insert(report.roots,{path=root:GetFullName(),children=children})
    for index,node in ipairs(root:GetDescendants())do
        if visited[node]then continue end
        visited[node]=true;scanned+=1
        if index>60000 or scanned>150000 then report.limited=true;break end
        if node:IsA("LuaSourceContainer") and #report.modules<100 and
            (relevant(node.Name) or node.Name=="FruitAnimator" or node.Name=="FruitModels")then
            table.insert(report.modules,{path=node:GetFullName(),class=node.ClassName})
        elseif not seen[node] and #report.sources<80 and (node:IsA("Tool") or node:IsA("Model"))
            and relevant(node.Name) and node:FindFirstChild("Fruit")then
            seen[node]=true;table.insert(report.sources,inspect(node))
        end
        if index%500==0 then task.wait()end
    end
end
report.scanned=scanned
report.moduleLimitReached=#report.modules>=100
report.sourceLimitReached=#report.sources>=80
report.complete=not (report.limited or report.moduleLimitReached or report.sourceLimitReached)
writefile(output,Http:JSONEncode(report))
print("Current fruit source audit saved: "..output.." | sources="..#report.sources.." | complete="..tostring(report.complete))
return report
