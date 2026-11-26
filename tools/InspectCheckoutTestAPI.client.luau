-- Inspect exported native test/view APIs only. Do not render or dispatch any purchase action.
assert(game.GameId==994732206,"Run in Blox Fruits")
local Http=game:GetService("HttpService")
local report={schemaVersion=1,placeId=game.PlaceId,modules={}}
local core=game:GetService("CorePackages")
local root=core
for _,name in ipairs({"Workspace","Packages","_Workspace","PurchasePrompt","PurchasePrompt"})do root=root and root:FindFirstChild(name)end
for _,path in ipairs({"Test.MockStore","Test.MockNetwork","Test.UnitTestContainer","Components.ProductPurchase.ProductPurchasePrompt","Components.PurchasePromptApp"})do
    local node=root
    for name in path:gmatch("[^.]+")do node=node and node:FindFirstChild(name)end
    local row={path=path,found=node~=nil}
    if node then
        local result
        local worker=task.spawn(function()result=table.pack(pcall(require,node))end)
        local deadline=os.clock()+3
        while not result and os.clock()<deadline do task.wait(.05)end
        if not result then pcall(task.cancel,worker);row.error="Require timed out"
        elseif result[1]then
            local value=result[2];row.type=typeof(value)
            if type(value)=="table"then
                row.keys={}
                for key,entry in pairs(value)do
                    local record={key=tostring(key),type=typeof(entry)}
                    if type(entry)=="function"then
                        local ok,count,variadic=pcall(debug.info,entry,"a")
                        if ok then record.parameters=count;record.variadic=variadic end
                    end
                    table.insert(row.keys,record)
                    if #row.keys>=35 then row.limited=true;break end
                end
            elseif type(value)=="function"then
                local ok,count,variadic=pcall(debug.info,value,"a")
                if ok then row.parameters=count;row.variadic=variadic end
            end
        else row.error=tostring(result[2])end
    end
    table.insert(report.modules,row)
end
report.complete=true
writefile("blox-catalog-checkout-test-api-"..game.PlaceId..".json",Http:JSONEncode(report))
print("Native checkout test/view API report saved")
return report
