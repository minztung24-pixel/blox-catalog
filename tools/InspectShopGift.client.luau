-- Read visible shop/gift UI structure; never activate buttons or invoke purchase APIs.
assert(game.GameId==994732206,"Run in Blox Fruits")
assert(type(writefile)=="function","Run in Potassium")
local Http=game:GetService("HttpService")
local player=assert(game:GetService("Players").LocalPlayer,"Run on the client")
local playerGui=player:WaitForChild("PlayerGui")
local report={schemaVersion=1,placeId=game.PlaceId,complete=false,snapshots={}}
local filename="blox-catalog-shop-gift-ui-"..game.PlaceId..".json"
local function visible(node)
    local current=node
    while current and current~=playerGui do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") and not current.Enabled then return false end
        current=current.Parent
    end
    return true
end
local function vector(value)return {value.X,value.Y}end
local function udim(value)return {value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset}end
local function snapshot()
    local roots={}
    local visited=0
    local catalog=playerGui:FindFirstChild("BloxCatalogSim")
    for _,node in ipairs(playerGui:GetDescendants())do
        visited+=1
        if visited>12000 then report.scanLimited=true;break end
        local name=node.Name:lower()
        if (node:IsA("GuiObject") or node:IsA("ScreenGui")) and visible(node)
            and (name:find("shop",1,true) or name:find("gift",1,true) or name:find("purchase",1,true))
            and (not catalog or not node:IsDescendantOf(catalog))then
            local nested=false
            for _,root in ipairs(roots)do if node:IsDescendantOf(root)then nested=true;break end end
            if not nested and #roots<12 then table.insert(roots,node)end
        end
    end
    local rows={}
    for _,root in ipairs(roots)do
        local nodes={root}
        for _,node in ipairs(root:GetDescendants())do
            if #nodes>=1800 then report.treeLimited=true;break end
            table.insert(nodes,node)
        end
        for _,node in ipairs(nodes)do
            if node:IsA("GuiObject")then
                local row={path=node:GetFullName(),class=node.ClassName,visible=visible(node),
                    position=udim(node.Position),size=udim(node.Size),anchor=vector(node.AnchorPoint),
                    absolutePosition=vector(node.AbsolutePosition),absoluteSize=vector(node.AbsoluteSize),
                    zIndex=node.ZIndex,active=node.Active,layoutOrder=node.LayoutOrder}
                if node:IsA("TextLabel") or node:IsA("TextButton")then row.text=node.Text end
                if node:IsA("TextBox")then row.placeholder=node.PlaceholderText end
                if node:IsA("ImageLabel") or node:IsA("ImageButton")then row.image=node.Image end
                for _,key in ipairs({"ItemId","ProductId","Price","PriceInRobux","TargetUserId"})do
                    local value=node:GetAttribute(key)
                    if type(value)=="number" or type(value)=="string" or type(value)=="boolean"then
                        row.attributes=row.attributes or {};row.attributes[key]=value
                    end
                end
                table.insert(rows,row)
            end
        end
    end
    return rows
end
print("Shop / Gift observer ready: mo Shop > Permanent Fruit > Gift, chuyen Server / Global. Chi xem, khong bam nut mua.")
local previous
local ok,message=pcall(function()
    for sample=1,31 do
        local rows=snapshot()
        local encoded=Http:JSONEncode(rows)
        if encoded~=previous then
            table.insert(report.snapshots,{sample=sample,nodes=rows})
            previous=encoded
            writefile(filename,Http:JSONEncode(report))
        end
        if sample<31 then task.wait(2)end
    end
end)
report.complete=ok
if not ok then report.error=tostring(message)end
writefile(filename,Http:JSONEncode(report))
print("Shop / Gift UI saved: "..filename.." | complete="..tostring(report.complete))
return report
