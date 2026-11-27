-- Read native item metadata and preserve only genuine physical Tools already replicated to this client.
assert(game.GameId==994732206,"Run in Blox Fruits")
local Http=game:GetService("HttpService")
local player=game:GetService("Players").LocalPlayer
local text=readfile("blox-catalog-sim-v12.26.lua")
local count
text,count=text:gsub("return UI%.start%(%)%s*$","return {Catalog=Catalog,Equipment=Equipment,FruitModels=FruitModels,FruitArchive=FruitArchive,FruitAnimations=FruitAnimations}")
assert(count==1,"Expected the standalone Catalog")
local modules=assert(loadstring(text,"ReportedFruitModules"))()
local archive=modules.FruitArchive.new()
local wanted={ ["1428"]=true,["1429"]=true,["1390"]=true,["1397"]=true,["1425"]=true,["1409"]=true }
local report={schemaVersion=1,complete=false,configs={},stock={},tools={},archive={},archiveLoad={}}
local function encode(value,depth)
    local kind=typeof(value)
    if kind=="string"then return value:sub(1,400)
    elseif kind=="number"or kind=="boolean"then return value
    elseif kind=="Vector2"then return {value.X,value.Y}
    elseif kind=="Vector3"then return {value.X,value.Y,value.Z}
    elseif kind=="Color3"then return {value.R,value.G,value.B}
    elseif kind=="EnumItem"then return tostring(value)
    elseif kind=="table"and depth<5 then
        local result,n={},0
        for key,child in pairs(value)do
            n+=1;if n>100 then result._limited=true;break end
            if type(key)=="string"or type(key)=="number"then result[tostring(key)]=encode(child,depth+1)end
        end
        return result
    end
end
local loaded={}
if type(getloadedmodules)=="function"then for _,node in pairs(getloadedmodules())do loaded[node]=true end end
local storage=game:GetService("ReplicatedStorage")
for _,name in ipairs({"ItemConfig","ItemReplicationService"})do
    local node=storage:FindFirstChild(name)
    if node and loaded[node]then
        local ok,api=pcall(require,node)
        if ok then for id in pairs(wanted)do
            if name=="ItemConfig"then
                local found,config=pcall(api.tryGet,tonumber(id))
                if found then report.configs[id]=encode(config,0)end
            elseif api.KEYS and api.ReadItem then
                local found,quantity=pcall(api.ReadItem,api,api.KEYS.QUANTITY,tonumber(id),nil)
                report.stock[id]={readable=found,quantity=found and quantity or nil}
            end
        end end
    end
end
for _,root in pairs({player.Character,player:FindFirstChildOfClass("Backpack")})do
    for _,tool in ipairs(root:GetChildren())do
        local id=tostring(tool:GetAttribute("ItemId")or "")
        local item=modules.Catalog.byId[id]
        if tool:IsA("Tool")and item and (item.category=="Fruits"or item.isPhysicalFruit)
            and not tool:GetAttribute("BloxCatalogOwned")and not tool:GetAttribute("ClientCatalogOwned")then
            local row={id=id,name=item.name,held=root==player.Character,parts=0,fx={},animations={},scripts={}}
            table.insert(report.tools,row)
            for _,node in ipairs(tool:GetDescendants())do
                if node:IsA("BasePart")then row.parts+=1
                elseif node:IsA("ParticleEmitter")or node:IsA("Beam")or node:IsA("Trail")then
                    table.insert(row.fx,{name=node.Name,class=node.ClassName,enabled=node.Enabled,texture=node.Texture})
                elseif node:IsA("Animation")then table.insert(row.animations,node.AnimationId)
                elseif node:IsA("LuaSourceContainer")then table.insert(row.scripts,{name=node.Name,class=node.ClassName})end
            end
            local clean=modules.Equipment.clone(tool,item)
            if clean then
                local saved,message=archive:save(item,clean)
                row.saved=saved==true;row.error=not saved and tostring(message)or nil
                clean:Destroy()
            end
        end
    end
end
for id in pairs(wanted)do report.archive[id]=archive:available(modules.Catalog.byId[id])end
for _,id in ipairs({"1424","1525","1395"})do
    local model,message=archive:load(modules.Catalog.byId[id])
    report.archiveLoad[id]={passed=model~=nil,error=message}
    if model then model:Destroy()end
end
archive:close()
report.complete=true
writefile("blox-catalog-reported-fruits-v1.json",Http:JSONEncode(report))
print("Reported fruit check saved; native Tools="..#report.tools)
return report
