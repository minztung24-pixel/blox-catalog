-- Inspect native checkout UI and keep sanitized, unparented UI copies. No purchase APIs/callbacks.
assert(game.GameId==994732206,"Run in Blox Fruits")
assert(type(writefile)=="function","Run in Potassium")
local Http=game:GetService("HttpService")
local Core=game:GetService("CoreGui")
local Collection=game:GetService("CollectionService")
local report={schemaVersion=1,placeId=game.PlaceId,roots={},nodes={},otherNodes={}}
local roots={}
local purchase=Core:FindFirstChild("PurchasePromptApp")
if purchase then table.insert(roots,purchase)end
local function value(v)
    local t=typeof(v)
    if t=="Vector2"then return {type=t,x=v.X,y=v.Y}end
    if t=="UDim"then return {type=t,scale=v.Scale,offset=v.Offset}end
    if t=="UDim2"then return {type=t,xs=v.X.Scale,xo=v.X.Offset,ys=v.Y.Scale,yo=v.Y.Offset}end
    if t=="Color3"then return {type=t,r=v.R,g=v.G,b=v.B}end
    if t=="EnumItem"then return {type=t,value=tostring(v)}end
    if t=="string" or t=="number" or t=="boolean"then return v end
end
local properties={"Visible","Enabled","DisplayOrder","ZIndexBehavior","ScreenInsets","IgnoreGuiInset",
    "Position","Size","AnchorPoint","ZIndex","LayoutOrder","Rotation","BackgroundColor3","BackgroundTransparency",
    "BorderSizePixel","BorderColor3","ClipsDescendants","AutomaticSize","Active","Selectable","Interactable",
    "Text","TextSize","TextColor3","TextTransparency","Font","TextScaled","TextWrapped","RichText","TextXAlignment","TextYAlignment",
    "Image","ImageColor3","ImageTransparency","ImageRectOffset","ImageRectSize","ScaleType","CornerRadius",
    "Thickness","Color","Transparency","AspectRatio","FillDirection","HorizontalAlignment","VerticalAlignment","Padding","SortOrder"}
local copies={}
local ok,message=pcall(function()
    for _,root in ipairs(roots)do
        local row={path=root:GetFullName(),class=root.ClassName}
        local success,clone=pcall(root.Clone,root)
        if success and clone then
            for _,node in ipairs(clone:GetDescendants())do
                if node:IsA("LuaSourceContainer") or node:IsA("RemoteEvent") or node:IsA("RemoteFunction")
                    or node:IsA("BindableEvent") or node:IsA("BindableFunction")then node:Destroy()end
            end
            for _,node in ipairs(clone:GetDescendants())do for _,tag in ipairs(Collection:GetTags(node))do Collection:RemoveTag(node,tag)end end
            for _,tag in ipairs(Collection:GetTags(clone))do Collection:RemoveTag(clone,tag)end
            clone:SetAttribute("BloxCatalogOwned",true)
            table.insert(copies,{path=row.path,instance=clone})
            row.copied=true
        else row.cloneError=tostring(clone)end
        table.insert(report.roots,row)
        local nodes={root}
        for _,node in ipairs(root:GetDescendants())do if #nodes>=2500 then report.limited=true;break end;table.insert(nodes,node)end
        for _,node in ipairs(nodes)do
            if node:IsA("GuiObject") or node:IsA("ScreenGui") or node:IsA("UIComponent")then
                local record={path=node:GetFullName(),class=node.ClassName,properties={}}
                for _,key in ipairs(properties)do
                    local readable,v=pcall(function()return node[key]end)
                    if readable then record.properties[key]=value(v)end
                end
                table.insert(report.nodes,record)
            else table.insert(report.otherNodes,{path=node:GetFullName(),class=node.ClassName,children=#node:GetChildren()})end
        end
    end
end)
if type(getgenv)=="function"then
    local env=getgenv()
    for _,entry in ipairs(env.BloxCatalogNativeCheckoutTemplates or {})do
        if entry.instance:GetAttribute("BloxCatalogOwned")then entry.instance:Destroy()end
    end
    env.BloxCatalogNativeCheckoutTemplates=copies
else for _,entry in ipairs(copies)do entry.instance:Destroy()end end
report.complete=ok
if not ok then report.error=tostring(message)end
local output="blox-catalog-native-checkout-ui-"..game.PlaceId..".json"
writefile(output,Http:JSONEncode(report))
print("Native checkout UI saved: "..output.." | roots="..#report.roots)
return report
