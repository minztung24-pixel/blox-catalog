-- Validate private captures of three existing local models, without equipping or requesting game resources.
assert(game.GameId==994732206,"Run in Blox Fruits")
local Http=game:GetService("HttpService")
local source=readfile("blox-catalog-sim-v12.25.lua")
local count
source,count=source:gsub("return UI%.start%(%)%s*$","return {Catalog=Catalog,Equipment=Equipment,FruitModels=FruitModels,FruitArchive=FruitArchive,FruitAnimations=FruitAnimations}")
assert(count==1,"Expected the standalone client")
local modules=assert(loadstring(source,"CaptureRoundTripModules"))()
local cache=modules.FruitModels.new()
local archive=modules.FruitArchive.new()
local report={schemaVersion=1,complete=false,passed=false,results={},scope="Existing local files only; no new model recovery"}
for _,id in ipairs({"1424","1525","1395"})do
    local item=assert(modules.Catalog.byId[id])
    local row={id=id,passed=false};table.insert(report.results,row)
    local copy,restored
    local ok,message=pcall(function()
        copy=assert(modules.Equipment.clone(assert(cache:load(item)),item))
        row.rig=modules.FruitAnimations.signature(copy)
        assert(archive:save(item,copy))
        local cold=modules.FruitArchive.new()
        restored=assert(cold:load(item));cold:close()
        assert(tostring(restored:GetAttribute("ItemId"))==id,"Wrong physical identity")
        assert(modules.FruitAnimations.signature(restored)==row.rig,"Rig changed")
        row.nodes=#restored:GetDescendants()
        row.passed=true
    end)
    if not ok then row.error=tostring(message)end
    if copy then copy:Destroy()end
    if restored then restored:Destroy()end
    writefile("blox-catalog-capture-roundtrip-v1.json",Http:JSONEncode(report))
    if not row.passed then break end
end
cache:close();archive:close()
report.complete=#report.results==3
report.passed=report.complete
for _,row in ipairs(report.results)do if not row.passed then report.passed=false end end
writefile("blox-catalog-capture-roundtrip-v1.json",Http:JSONEncode(report))
print("Captured Fruit round-trip saved | passed="..tostring(report.passed))
return report
