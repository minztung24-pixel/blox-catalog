-- Read-only UI/source snapshot. Does not require modules, activate buttons or call remotes.
assert(game.GameId==994732206,"Run in Blox Fruits")
assert(type(writefile)=="function","Run in Potassium")
local Http=game:GetService("HttpService")
local storage=game:GetService("ReplicatedStorage")
local player=assert(game:GetService("Players").LocalPlayer)
local report={schemaVersion=1,placeId=game.PlaceId,modules={},ui={},errors={},complete=false}
local camera=workspace.CurrentCamera
report.viewport=camera and {camera.ViewportSize.X,camera.ViewportSize.Y}
local top,bottom=game:GetService("GuiService"):GetGuiInset()
report.guiInset={top.X,top.Y,bottom.X,bottom.Y}
local paths={
    {"React","Components","NotificationFeed","Notification","Label"},
    {"React","Components","NotificationFeed","Notification","Root"},
    {"React","Components","NotificationFeed","Notification","TextLayer"},
    {"React","Components","NotificationFeed","Notification","Banner"},
    {"React","Components","NotificationFeed","CONSTANTS"},
    {"Modules","Util","TextUtil"},
    {"React","Hooks","NotificationFeed","useFormattedText"},
    {"Util","RichText","ColorPalette"},
    {"React","CONSTANTS"},
}
for _,parts in ipairs(paths)do
    local node=storage
    for _,name in ipairs(parts)do node=node and node:FindFirstChild(name)end
    local row={path="ReplicatedStorage."..table.concat(parts,".")}
    if node and node:IsA("ModuleScript")and type(decompile)=="function"then
        local result
        local worker=task.spawn(function()result=table.pack(pcall(decompile,node))end)
        local deadline=os.clock()+3
        while not result and os.clock()<deadline do task.wait(.05)end
        if not result then pcall(task.cancel,worker);row.error="Timed out"
        elseif result[1]and type(result[2])=="string"then row.source=result[2]:sub(1,50000);row.truncated=#result[2]>50000
        else row.error=tostring(result[2])end
    else row.error="Module or decompiler unavailable"end
    table.insert(report.modules,row)
end
local function snapshot(root)
    if not root then return end
    local nodes={root}
    for _,node in ipairs(root:GetDescendants())do if #nodes>=400 then break end;table.insert(nodes,node)end
    for _,node in ipairs(nodes)do
        local ok,row=pcall(function()
            local data={path=node:GetFullName(),class=node.ClassName}
            if node:IsA("ScreenGui")then
                data.enabled=node.Enabled;data.insets=tostring(node.ScreenInsets);data.ignoreGuiInset=node.IgnoreGuiInset
                data.order=node.DisplayOrder
            end
            if node:IsA("GuiObject")then
                data.position={node.AbsolutePosition.X,node.AbsolutePosition.Y}
                data.size={node.AbsoluteSize.X,node.AbsoluteSize.Y};data.visible=node.Visible
            end
            if node:IsA("TextLabel")or node:IsA("TextButton")then
                data.text=node.Text;data.textSize=node.TextSize;data.font=node.FontFace.Family
                data.weight=tostring(node.FontFace.Weight)
                data.color={node.TextColor3.R,node.TextColor3.G,node.TextColor3.B}
                data.stroke={node.TextStrokeColor3.R,node.TextStrokeColor3.G,node.TextStrokeColor3.B,node.TextStrokeTransparency}
            end
            return data
        end)
        if ok then table.insert(report.ui,row)else table.insert(report.errors,tostring(row))end
    end
end
snapshot(player.PlayerGui:FindFirstChild("BloxCatalogCheckout"))
snapshot(player.PlayerGui:FindFirstChild("GiftWindow"))
local ok,core=pcall(game.GetService,game,"CoreGui")
if ok then
    for _,root in ipairs(core:GetChildren())do
        if root.Name=="PurchasePromptApp"then snapshot(root)end
    end
end
report.complete=true
local filename="blox-catalog-checkout-layout-"..game.PlaceId..".json"
writefile(filename,Http:JSONEncode(report))
print("Checkout layout saved: "..filename.." | modules="..#report.modules.." | nodes="..#report.ui)
return report
