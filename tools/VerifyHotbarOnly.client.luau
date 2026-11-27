-- Exercise only this Catalog's local Add callbacks; no game purchase, Drop, Eat or asset request.
assert(game.GameId==994732206 and type(getconnections)=="function","Run in Blox Fruits with readable local UI connections")
local Http=game:GetService("HttpService")
local player=game:GetService("Players").LocalPlayer
local report={schemaVersion=1,complete=false,passed=false,results={}}
local ok,message=pcall(function()
    local gui=assert(loadstring(readfile("blox-catalog-sim-v12.26.lua"),"BloxCatalog"))()
    report.version=gui:GetAttribute("Version")
    local info=gui:FindFirstChild("SnapshotInfo",true)
    local deadline=os.clock()+8
    repeat task.wait(.1)until info:GetAttribute("ItemsLinked")or os.clock()>deadline
    report.itemsLinked=info:GetAttribute("ItemsLinked")==true
    assert(report.itemsLinked,"Items must be linked before testing Add")
    local search=assert(gui:FindFirstChild("Search",true))
    for _,id in ipairs({"1428","1429"})do
        search.Text=id;task.wait(.15)
        local card=assert(gui:FindFirstChild("Item_"..id,true),"Missing fixture target card")
        local action=assert(card:FindFirstChild("Action"))
        local callbacks=getconnections(action.Activated)
        assert(#callbacks==1 and type(callbacks[1].Function)=="function","Unexpected local Add bindings")
        callbacks[1].Function();task.wait(.2)
        local found
        for _,tool in ipairs(player.Backpack:GetChildren())do
            if tool:IsA("Tool")and tostring(tool:GetAttribute("ItemId"))==id and tool:GetAttribute("BloxCatalogOwned")then
                assert(not found,"Duplicate local hotbar entries");found=tool
            end
        end
        local row={id=id,passed=found~=nil}
        table.insert(report.results,row)
        assert(found,"Local Add did not create a hotbar Tool")
        row.name=found.Name;row.noGeometry=not found:FindFirstChildWhichIsA("BasePart",true)
        row.disabled=not found.Enabled and found.ManualActivationOnly and not found.RequiresHandle
        row.marked=found:GetAttribute("BloxCatalogHotbarOnly")==true
        row.passed=row.noGeometry and row.disabled and row.marked
        assert(row.passed,"Hotbar metadata must not act as a physical Fruit")
    end
    search.Text=""
    report.passed=true
end)
report.complete=true
if not ok then report.error=tostring(message)end
writefile("blox-catalog-hotbar-only-check-v1.json",Http:JSONEncode(report))
print("Celestial/Oni local hotbar check saved | passed="..tostring(report.passed))
return report
