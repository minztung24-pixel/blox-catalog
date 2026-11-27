-- Read-only: native hotbar/skill UI, Tool metadata and inventory mastery sources.
assert(game.GameId==994732206 and type(writefile)=="function","Run in Blox Fruits with Potassium")
local player=game:GetService("Players").LocalPlayer
local storage=game:GetService("ReplicatedStorage")
local report={schemaVersion=1,placeId=game.PlaceId,modules={},scripts={},tools={},ui={},complete=false}
local seen={}
local function inspect(node)
    if seen[node] or #report.modules>=45 or not node:IsA("LuaSourceContainer")then return end
    seen[node]=true
    local row={path=node:GetFullName()}
    if type(decompile)=="function"then
        local result
        local worker=task.spawn(function()result=table.pack(pcall(decompile,node))end)
        local deadline=os.clock()+2
        while not result and os.clock()<deadline do task.wait(.04)end
        if not result then pcall(task.cancel,worker);row.error="Timeout"
        elseif result[1]and type(result[2])=="string"then row.source=result[2]:sub(1,65000);row.truncated=#result[2]>65000
        else row.error=tostring(result[2])end
    end
    table.insert(report.modules,row)
end
for _,path in ipairs({"Controllers.UI.Inventory","Controllers.UI.Backpack","Controllers.UI.Skills","Controllers.UI.HUD","ItemReplicationService","ItemConfig","FruitSkills","Modules.FruitSkillUtil","Util.ItemReplication","React.Factories.Hooks.ItemReplication","React.Components.Inventory","React.Components.Inventory.ItemCard","React.Components.Inventory.ItemCard.Display","React.Hooks.Item.useMovesetElements","React.Hooks.Item.Config.useMoveset","React.Hooks.Item.Config.usePhysicalMoveset","React.Hooks.Item","Controllers.UI.SelectedSkill","JobsReplicated.SkillsInterface"})do
    local node=storage
    for name in path:gmatch("[^.]+")do node=node and node:FindFirstChild(name)end
    if node then inspect(node)
        if path=="Controllers.UI.Inventory"or path=="React.Components.Inventory"or path=="React.Hooks.Item"then
            for _,child in ipairs(node:GetDescendants())do
                if child:IsA("ModuleScript")then table.insert(report.scripts,child:GetFullName())end
                local name=child.Name:lower()
                if name:find("mastery",1,true)or name:find("detail",1,true)or name:find("preview",1,true)or child.Name=="getTiles"then inspect(child)end
            end
        end
    end
end
local mainController=player.PlayerGui:FindFirstChild("Main")and player.PlayerGui.Main:FindFirstChild("UIController")
if mainController then inspect(mainController);local setup=mainController:FindFirstChild("SetUpSkills");if setup then inspect(setup)end end
local backpackUI=player.PlayerGui:FindFirstChild("Backpack")
if backpackUI then for _,node in ipairs(backpackUI:GetDescendants())do if node:IsA("LuaSourceContainer")then inspect(node)end end end
report.runtimeScripts={}
for _,root in pairs({player.PlayerGui,player:FindFirstChildOfClass("PlayerScripts")})do
    for _,node in ipairs(root:GetDescendants())do
        if node:IsA("LuaSourceContainer")and #report.runtimeScripts<250 then table.insert(report.runtimeScripts,node:GetFullName())end
    end
end
if type(getloadedmodules)=="function"then
    for _,node in pairs(getloadedmodules())do
        local path=node:GetFullName():lower()
        if path:find("hotbar",1,true)or path:find("backpack",1,true)or path:find("skill",1,true)or path:find("moveset",1,true)then
            table.insert(report.scripts,node:GetFullName())
            if node.Name:lower():find("backpack",1,true)or node.Name:lower():find("hotbar",1,true)or node.Name=="Skills"then inspect(node)end
        end
    end
end
for _,root in pairs({player:FindFirstChildOfClass("PlayerScripts"),storage:FindFirstChild("Controllers"),player.PlayerGui:FindFirstChild("Main")})do
    local nodes=root:GetDescendants()
    for i,node in ipairs(nodes)do
        if i>16000 then break end
        if node:IsA("LuaSourceContainer")then
            local name=node.Name:lower()
            if name:find("backpack",1,true)or name:find("hotbar",1,true)or name=="skills"or name=="moveset"or name=="mastery"then
                table.insert(report.scripts,node:GetFullName());inspect(node)
            end
        end
    end
end
for _,root in pairs({player:FindFirstChildOfClass("Backpack"),player.Character})do
    for _,tool in ipairs(root:GetChildren())do if tool:IsA("Tool")then
        local row={name=tool.Name,parent=root.ClassName,tooltip=tool.ToolTip,attributes=tool:GetAttributes(),children={}}
        for _,node in ipairs(tool:GetDescendants())do
            if #row.children>=40 then break end
            if node:IsA("ValueBase")then table.insert(row.children,{name=node.Name,class=node.ClassName,value=tostring(node.Value)})end
        end
        table.insert(report.tools,row)
    end end
end
local main=player.PlayerGui:FindFirstChild("Main")
if main then for i,node in ipairs(main:GetDescendants())do
    if i>2500 then break end
    if node:IsA("GuiObject")then
        local path=node:GetFullName()
        if path:find("Skills",1,true)or path:find("Mastery",1,true)or path:find("Hotbar",1,true)or path:find("InventoryContainer.Left",1,true)then
            local row={path=path,class=node.ClassName,visible=node.Visible}
            if node:IsA("TextLabel")or node:IsA("TextButton")then row.text=node.Text end
            if node:IsA("ImageLabel")or node:IsA("ImageButton")then row.image=node.Image end
            table.insert(report.ui,row)
        end
    end
end end
report.complete=true
local loaded={}
if type(getloadedmodules)=="function"then for _,node in pairs(getloadedmodules())do loaded[node]=true end end
local configModule=storage:FindFirstChild("ItemConfig")
local serviceModule=storage:FindFirstChild("ItemReplicationService")
if serviceModule and loaded[serviceModule]then
    local ok,service=pcall(require,serviceModule)
    if ok then
        report.combat={}
        for _,id in ipairs({128,1225,1184,1144,1113,402,350,349,1411,1399})do
            local data={id=id}
            for _,key in ipairs({"Mastery","CombatData"})do
                local got,value=pcall(service.ReadItem,service,key,id,nil)
                if got then data[key]=value end
            end
            table.insert(report.combat,data)
        end
    end
end
report.setupCaptures={}
if mainController and type(debug.getupvalues)=="function"then
    local node=mainController:FindFirstChild("SetUpSkills")
    if node and loaded[node]then
        local ok,fn=pcall(require,node)
        if ok and type(fn)=="function"then
            for index,value in pairs(debug.getupvalues(fn))do
                local row={index=index,type=type(value)}
                if type(value)=="function"then local got,name=pcall(debug.info,value,"n");if got then row.name=name end end
                table.insert(report.setupCaptures,row)
            end
        end
    end
end
if configModule and loaded[configModule]then
    local ok,configs=pcall(require,configModule)
    if ok then
        report.configs={}
        for _,id in ipairs({128,1225,1184,1144,1113,1399,1393,1411,1517,358,349,370})do
            local got,value=pcall(configs.tryGet,id)
            if got and value then
                local encoded,json=pcall(game:GetService("HttpService").JSONEncode,game:GetService("HttpService"),value)
                table.insert(report.configs,{id=id,data=encoded and game:GetService("HttpService"):JSONDecode(json)or nil,error=not encoded and tostring(json)or nil})
            end
        end
    end
end
local filename="blox-catalog-ability-slots-"..game.PlaceId..".json"
writefile(filename,game:GetService("HttpService"):JSONEncode(report))
print("Ability slots saved: "..filename.." | modules="..#report.modules)
return report
