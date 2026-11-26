-- Read client UI scripts and the open gift window; never invoke callbacks or transactions.
assert(game.GameId==994732206,"Run in Blox Fruits")
assert(type(writefile)=="function" and type(decompile)=="function","Potassium decompile/writefile required")
local Http=game:GetService("HttpService")
local player=assert(game:GetService("Players").LocalPlayer,"Run on the client")
local playerGui=player:WaitForChild("PlayerGui")
local report={schemaVersion=2,placeId=game.PlaceId,modules={},candidates={},window={}}
local output="blox-catalog-gift-checkout-v2-"..game.PlaceId..".json"
local storage=game:GetService("ReplicatedStorage")
local roots={}
for _,name in ipairs({"Controllers","SaleService","PriceService","Notification"})do
    local root=storage:FindFirstChild(name)
    if root then table.insert(roots,root)end
end
local modules=storage:FindFirstChild("Modules")
local asset=modules and modules:FindFirstChild("Asset")
local wrapper=asset and asset:FindFirstChild("WrapPurchase")
if wrapper then table.insert(roots,wrapper)end
local giftWindow=playerGui:FindFirstChild("GiftWindow")
if giftWindow then table.insert(roots,giftWindow)end
local playerScripts=player:FindFirstChild("PlayerScripts")
if playerScripts then table.insert(roots,playerScripts)end
table.insert(roots,storage)
local candidates={}
local seen={}
local function consider(node)
    if seen[node] then return end
    seen[node]=true
    if node:IsA("ModuleScript") or node:IsA("LocalScript")then
        local path=node:GetFullName()
        local lower=path:lower()
        local ui=lower:find("controller",1,true) or lower:find(".ui.",1,true) or (playerScripts and node:IsDescendantOf(playerScripts))
        local score=lower:find("confirmationdialog",1,true) and node.Name=="Controller" and 80
            or node.Name=="WrapPurchase" and 60
            or node.Name=="Notification" and 55
            or node.Name:lower():find("gift",1,true) and 40
            or lower:find("gift",1,true) and 30
            or lower:find("purchaseprompt",1,true) and 25
            or (node.Name=="SaleService" or node.Name=="PriceService") and 20
            or (ui and lower:find("purchase",1,true)) and 6
            or (ui and lower:find("shop",1,true)) and 2
            or 0
        if score>0 then table.insert(candidates,{node=node,path=path,score=score})end
    end
end
if type(getloadedmodules)=="function"then
    local ok,modules=pcall(getloadedmodules)
    if ok then for _,node in pairs(modules)do if typeof(node)=="Instance"then consider(node)end end end
end
for _,root in ipairs(roots)do
    consider(root)
    local visited=0
    for _,node in ipairs(root:GetDescendants())do
        visited+=1
        if visited>25000 then report.scanLimited=true;break end
        consider(node)
    end
end
table.sort(candidates,function(a,b)return a.score==b.score and a.path<b.path or a.score>b.score end)
for _,entry in ipairs(candidates)do table.insert(report.candidates,{path=entry.path,score=entry.score})end
if giftWindow then
    local count=0
    for _,node in ipairs(giftWindow:GetDescendants())do
        count+=1
        if count>2000 then report.windowLimited=true;break end
        if node:IsA("TextLabel") or node:IsA("TextButton") or node:IsA("ImageButton")then
            table.insert(report.window,{path=node:GetFullName(),class=node.ClassName,
                text=(node:IsA("TextLabel") or node:IsA("TextButton")) and node.Text or nil,
                visible=node.Visible})
        end
    end
end
print("Gift checkout reader started. Chi doc script/UI; khong bam mua hay goi remote.")
for index=1,math.min(#candidates,14)do
    local entry=candidates[index]
    local result
    local worker=task.spawn(function()result=table.pack(pcall(decompile,entry.node))end)
    local deadline=os.clock()+5
    while not result and os.clock()<deadline do task.wait(.05)end
    local row={path=entry.path,class=entry.node.ClassName}
    if not result then
        pcall(task.cancel,worker);row.error="Decompile timed out"
    elseif result[1] and type(result[2])=="string"then
        row.source=result[2]:sub(1,80000);row.truncated=#result[2]>80000
    else row.error=tostring(result[2])end
    table.insert(report.modules,row)
    writefile(output,Http:JSONEncode(report))
    task.wait()
end
report.complete=true
report.selectionLimited=#candidates>14
writefile(output,Http:JSONEncode(report))
print("Gift checkout report saved: "..output.." | modules="..#report.modules)
return report
