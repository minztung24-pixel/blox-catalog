-- Read-only: cached catalog, native shop/asset code and replicated model candidates.
assert(game.GameId==994732206 and type(writefile)=="function","Run in Blox Fruits with Potassium")
local storage=game:GetService("ReplicatedStorage")
local player=game:GetService("Players").LocalPlayer
local Http=game:GetService("HttpService")
local output="blox-catalog-shop-fruit-assets-"..game.PlaceId..".json"
local report={schemaVersion=1,placeId=game.PlaceId,placeVersion=game.PlaceVersion,complete=false,
    modules={},trees={},configs={},models={},shopUi={},gachaUi={},limits={}}
local function save()writefile(output,Http:JSONEncode(report))end
local function bounded(fn,...)
    local args,result=table.pack(...),nil
    local worker=task.spawn(function()result=table.pack(pcall(fn,table.unpack(args,1,args.n)))end)
    local deadline=os.clock()+3
    while not result and os.clock()<deadline do task.wait(.03)end
    if not result then pcall(task.cancel,worker);return false,"Timed out"end
    return table.unpack(result,1,result.n)
end
local function resolve(path)
    local node=storage
    for name in path:gmatch("[^.]+")do node=node and node:FindFirstChild(name)end
    return node
end
local function scalar(value,depth,seen)
    local kind=typeof(value)
    if kind=="string"then return value:sub(1,2048)end
    if kind=="boolean"or kind=="number"then return value end
    if kind=="Instance"then return {class=value.ClassName,path=value:GetFullName()}end
    if kind=="Vector2"then return {x=value.X,y=value.Y}end
    if kind=="table"and depth>0 and not seen[value]then
        seen[value]=true
        local copy,count={},0
        for key,child in pairs(value)do
            count+=1;if count>200 then copy._limited=true;break end
            if type(key)=="string"or type(key)=="number"then
                local name=tostring(key)
                if not name:lower():match("secret")and not name:lower():match("password")and not name:lower():match("token")then
                    copy[name]=scalar(child,depth-1,seen)
                end
            end
        end
        seen[value]=nil;return copy
    end
    if kind~="nil"then return "<"..kind..">"end
end
local loaded={}
if type(getloadedmodules)=="function"then for _,node in pairs(getloadedmodules())do loaded[node]=true end end
local configModule=resolve("ItemConfig")
local names,ids={},{}
local function normalized(name)return name:lower():gsub("[%s%p]",""):gsub("fruit$","")end
assert(normalized("Dragon (West) Fruit")==normalized("Dragon (West)"))
assert(normalized("Control")~=normalized("Controller"))
if configModule and loaded[configModule]then
    local ok,config=bounded(require,configModule)
    if ok and type(config.dumpItems)=="function"then
        local read,items=bounded(config.dumpItems)
        if read then
            for _,item in pairs(items)do
                local index,display,skin=item.Index or {},item.Display or {},item.Skin or {}
                if index.IdType=="PhysicalMoveset"or skin.Type=="Fruit"or display.Category=="Blox Fruit"then
                    local row={fields={},data=scalar(item,9,{})}
                    for key,value in pairs(item)do row.fields[tostring(key)]=typeof(value)end
                    table.insert(report.configs,row)
                    if index.IdType=="PhysicalMoveset"then
                        ids[tostring(index.ItemId)]=true
                        for _,name in pairs({index.StorageKey,display.Name,index.DebugLabel})do
                            if type(name)=="string"then names[normalized(name)]=true end
                        end
                    end
                end
            end
        else report.configError=tostring(items)end
    else report.configError=tostring(config)end
else report.configError="ItemConfig not cached"end
local holder=player.PlayerGui:FindFirstChild("__ReplicatedSpinnerInstances")
report.preview={present=holder~=nil,children={}}
if holder then
    for _,child in ipairs(holder:GetChildren())do
        local row={name=child.Name,class=child.ClassName,id=child:GetAttribute("ItemId"),attributes=scalar(child:GetAttributes(),3,{})}
        if child:IsA("ObjectValue")then row.target=child.Value and child.Value:GetFullName()end
        table.insert(report.preview.children,row)
    end
end
save()
for _,path in ipairs({"Modules.Asset","Util","Shop","Shop.LIBRARY.PRODUCTS","React.Components","Controllers.UI",
    "ClientComponents","Assets","Assets.SkinnedRigs","Storage","StreamedQueue","Unloaded","Cache2","FX",
    "DialoguesList.NPCs","Controllers.UI.Gacha","React.Components.Gacha"})do
    local node=resolve(path)
    local row={path=path,children={}}
    if node then for _,child in ipairs(node:GetChildren())do
        table.insert(row.children,{name=child.Name,class=child.ClassName})
    end else row.missing=true end
    table.insert(report.trees,row)
end
local choices,seen={},{}
local function choose(node)
    if node and node:IsA("LuaSourceContainer")and not seen[node]then seen[node]=true;table.insert(choices,node)end
end
for _,path in ipairs({"ClientResourceLoader","Util.Modification","Util.SkinVFX","Modules.SkinVFXHandle",
    "Shop","Controllers.UI.Inventory.RemoteUtil","Modules.Asset.GetFruitName","Controllers.UI.FruitShop.StateUtil",
    "Controllers.UI.ModelPopup","Controllers.UI.PreviewSpinModelDebugger","Controllers.UI.ModificationsMenu",
    "React.Components.ModelPopup","Util.PreviewSpinModel","Util.PreviewModel","Modules.Asset.ItemData",
    "Definitions.Skin.Appearance","Controllers.UI.Spinner.Components.PreviewModel",
    "Controllers.UI.Spinner.SpinnerUtil","Controllers.UI.Spinner","Controllers.UI.Spinner.Helpers.Replicator",
    "DialoguesList.Library","Controllers.UI.Gacha","Controllers.GachaClient",
    "Controllers.UI.GachaWindow","Controllers.UI.GachaSimulation",
    "Controllers.UI.GachaWindow.Controllers.Cousin","React.Components.Gacha.Windows.Cousin",
    "React.Components.Gacha.FruitIcon","React.Components.Gacha.AnimatedTile"})do choose(resolve(path))end
local npcs=resolve("DialoguesList.NPCs")
if npcs then for _,node in ipairs(npcs:GetDescendants())do
    local name=node.Name:lower()
    if name:find("fruit",1,true)or name:find("gacha",1,true)or name:find("cousin",1,true)then choose(node)end
end end
report.streams={}
local queue=resolve("StreamedQueue")
if queue then for _,pointer in ipairs(queue:GetChildren())do
    if pointer:IsA("ObjectValue")then
        local target=pointer.Value
        local row={pointer=pointer.Name,unresolved=target==nil,children={}}
        if target then
            row.target=target:GetFullName();row.class=target.ClassName
            for _,child in ipairs(target:GetChildren())do
                if #row.children>=100 then row.limited=true;break end
                table.insert(row.children,{name=child.Name,class=child.ClassName})
            end
        end
        table.insert(report.streams,row)
    end
end end
for _,root in ipairs({storage,player.PlayerGui,workspace})do
    for i,node in ipairs(root:GetDescendants())do
        if node:IsA("LuaSourceContainer")and (node.Name:match("FruitShop")or node.Name=="Shop"or node.Name=="FruitAnimator")then choose(node)end
        if (node:IsA("Tool")or node:IsA("Model"))
            and (ids[tostring(node:GetAttribute("ItemId"))]or names[normalized(node.Name)])then
            if #report.models>=250 then report.limits.models=true;continue end
            local row={path=node:GetFullName(),class=node.ClassName,id=node:GetAttribute("ItemId"),name=node.Name,
                owned=node:GetAttribute("BloxCatalogOwned"),attributes=scalar(node:GetAttributes(),3,{}),parts=0,animations={},effects=0,scripts={}}
            for _,child in ipairs(node:GetDescendants())do
                if child:IsA("BasePart")then row.parts+=1
                elseif child:IsA("Animation")then table.insert(row.animations,child.AnimationId)
                elseif child:IsA("ParticleEmitter")or child:IsA("Beam")or child:IsA("Trail")then row.effects+=1
                elseif child:IsA("LuaSourceContainer")then table.insert(row.scripts,child:GetFullName())end
            end
            row.handle=node:FindFirstChild("Handle")~=nil
            table.insert(report.models,row)
        end
        if root==player.PlayerGui and (node:IsA("ImageLabel")or node:IsA("ImageButton")or node:IsA("ViewportFrame"))then
            local path=node:GetFullName()
            if path:find("Shop",1,true)and not path:find("BloxCatalogSim",1,true)then
                table.insert(report.shopUi,{path=path,class=node.ClassName,image=not node:IsA("ViewportFrame")and node.Image or nil})
            end
            if path:find("Gacha",1,true)and not path:find("BloxCatalogSim",1,true)then
                table.insert(report.gachaUi,{path=path,class=node.ClassName,image=not node:IsA("ViewportFrame")and node.Image or nil})
            end
        end
        if i%500==0 then task.wait()end
    end
end
save()
for i,node in ipairs(choices)do
    if i>45 then report.limits.modules=true;break end
    local row={path=node:GetFullName(),loaded=loaded[node]==true}
    if type(decompile)=="function"then
        local ok,source=bounded(decompile,node)
        if ok then row.source=source:sub(1,150000);row.truncated=#source>150000;if row.truncated then report.limits.source=true end
        else row.error=tostring(source)end
    end
    table.insert(report.modules,row);save();task.wait()
end
report.complete=not next(report.limits)
save()
print("Fruit / Skin / Shop sources saved: "..output.." | configs="..#report.configs.." | candidates="..#report.models)
return report
