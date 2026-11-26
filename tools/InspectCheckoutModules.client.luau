-- Read available native purchase UI module metadata/source. No requires or purchase actions.
assert(game.GameId==994732206,"Run in Blox Fruits")
assert(type(writefile)=="function" and type(decompile)=="function","Run in Potassium")
local Http=game:GetService("HttpService")
local report={schemaVersion=1,placeId=game.PlaceId,inventory={},modules={}}
local ok,core=pcall(game.GetService,game,"CorePackages")
local candidates,seen={},{}
local function inspect(node)
    if seen[node] or not node:IsA("ModuleScript")then return end
    seen[node]=true
    local path=node:GetFullName();local lower=path:lower();local name=node.Name:lower()
    if not (lower:find("purchase",1,true) or lower:find("robux",1,true))then return end
    table.insert(report.inventory,{path=path,class=node.ClassName})
    local score=name=="purchaseprompt" and 100 or name=="purchasecompleted" and 95
        or name:find("productpurchase",1,true) and 90
        or name:find("purchasecomplete",1,true) and 85
        or name=="productpurchaseprompt" and 80
        or name=="init" and 1 or 0
    if lower:find("mock",1,true) and score>0 then score-=10 end
    if score>0 then table.insert(candidates,{node=node,path=path,score=score})end
end
if ok then
    report.corePackagesAvailable=true
    local readable,nodes=pcall(core.GetDescendants,core)
    if readable then for _,node in ipairs(nodes)do inspect(node)end
    else report.error=tostring(nodes)end
else report.error=tostring(core)end
if type(getloadedmodules)=="function"then
    local readable,nodes=pcall(getloadedmodules)
    if readable then for _,node in pairs(nodes)do if typeof(node)=="Instance"then inspect(node)end end end
end
table.sort(candidates,function(a,b)return a.score==b.score and a.path<b.path or a.score>b.score end)
for index=1,math.min(8,#candidates)do
    local entry=candidates[index]
    local result
    local worker=task.spawn(function()result=table.pack(pcall(decompile,entry.node))end)
    local deadline=os.clock()+4
    while not result and os.clock()<deadline do task.wait(.05)end
    local row={path=entry.path}
    if not result then pcall(task.cancel,worker);row.error="Timed out"
    elseif result[1] and type(result[2])=="string"then row.source=result[2]:sub(1,80000);row.truncated=#result[2]>80000
    else row.error=tostring(result[2])end
    table.insert(report.modules,row)
end
report.complete=true
local filename="blox-catalog-checkout-modules-"..game.PlaceId..".json"
writefile(filename,Http:JSONEncode(report))
print("Checkout modules saved: "..filename.." | candidates="..#candidates)
return report
