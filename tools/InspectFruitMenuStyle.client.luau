-- Read-only menu identity, native renderer sources and currently mounted UI.
assert(game.GameId==994732206 and type(writefile)=="function","Run in Blox Fruits with Potassium")
local player=game:GetService("Players").LocalPlayer
local storage=game:GetService("ReplicatedStorage")
local report={schemaVersion=1,placeId=game.PlaceId,modules={},ui={},active={},complete=false}
local paths={"DialogueController","DialogueController.Dialogue.Window","DialogueController.ReactComponents",
    "DialogueController.ReactComponents.DialogueWindow","DialogueController.ReactComponents.Responses",
    "DialogueController.ReactComponents.Responses.ChatButton","DialogueController.ReactComponents.Responses.NevermindButton",
    "DialogueController.Builder.Dialogue","React.Components.DialogueSession","React.Components.DialogueWindow",
    "React.Components.LegacyThemeProvider","React.Hooks.Player.useTestGroup","TestingGroupUtil",
    "React.Components.DialogueWindow.ContextLayer","React.Components.DialogueWindow.Window",
    "React.Hooks.DialogueSession.usePageProps","Notification","DialogueController.Builder.Page"}
for _,path in ipairs(paths)do
    local node=storage
    for name in path:gmatch("[^.]+")do node=node and node:FindFirstChild(name)end
    local row={path="ReplicatedStorage."..path,children={}}
    if node then
        for _,child in ipairs(node:GetChildren())do table.insert(row.children,{name=child.Name,class=child.ClassName})end
        if node:IsA("ModuleScript")and type(decompile)=="function"then
            local result
            local worker=task.spawn(function()result=table.pack(pcall(decompile,node))end)
            local deadline=os.clock()+3
            while not result and os.clock()<deadline do task.wait(.04)end
            if not result then pcall(task.cancel,worker);row.error="Timeout"
            elseif result[1]then row.source=result[2]:sub(1,90000);row.truncated=#result[2]>90000
            else row.error=tostring(result[2])end
        end
    else row.missing=true end
    table.insert(report.modules,row)
end
local loaded={}
if type(getloadedmodules)=="function"then for _,node in pairs(getloadedmodules())do loaded[node]=true end end
local module=storage:FindFirstChild("DialogueController")
if module and loaded[module]then
    local ok,controller=pcall(require,module)
    if ok then
        local current=controller.getActiveDialogue()
        if current then
            local dialogue=current._dialogue
            local page=current.getCurrent and current:getCurrent()
            report.active={title=dialogue and dialogue._title,hasLayout=dialogue and dialogue._layout~=nil,
                windowType=type(current._window),optionCount=page and #(page._options or {})or nil}
        end
        if type(controller.isLegacyTheme)=="function"then report.legacyTheme=controller.isLegacyTheme()end
    end
end
local function snapshot(root)
    local count=0
    for _,node in ipairs(root:GetDescendants())do
        if count>=550 then break end
        if node:IsA("GuiObject")then
            local row={path=node:GetFullName(),class=node.ClassName,visible=node.Visible,
                position={node.AbsolutePosition.X,node.AbsolutePosition.Y},size={node.AbsoluteSize.X,node.AbsoluteSize.Y},background=node.BackgroundTransparency}
            if node:IsA("TextLabel")or node:IsA("TextButton")then row.text=node.Text;row.font=node.FontFace.Family;row.textSize=node.TextSize end
            if node:IsA("ImageLabel")or node:IsA("ImageButton")then row.image=node.Image end
            table.insert(report.ui,row);count+=1
        end
    end
end
for _,gui in ipairs(player.PlayerGui:GetChildren())do
    if gui:IsA("ScreenGui")and (gui.Name:lower():find("dialog",1,true)or gui.Name=="BloxCatalogSim"or gui.Name=="Notifications")then snapshot(gui)end
end
report.complete=true
local filename="blox-catalog-fruit-menu-style-"..game.PlaceId..".json"
writefile(filename,game:GetService("HttpService"):JSONEncode(report))
print("Fruit menu style saved: "..filename)
return report
