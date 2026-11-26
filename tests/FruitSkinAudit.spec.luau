return function(probeSource,bundleSource)
    local actualGame,compile=game,loadstring
    local character=Instance.new("Model")
    local backpack=Instance.new("Folder")
    local fake={GameId=994732206,PlaceId=0}
    local originalObjects={}
    function fake:GetService(name)
        if name=="Players"then return {LocalPlayer={Character=character,FindFirstChildOfClass=function()return backpack end}}end
        return actualGame:GetService(name)
    end
    function fake:GetObjects(path)
        local object=Instance.new("Tool")
        if path:find("Arcsteel Magnet",1,true)then object:SetAttribute("ItemId",1525)
        elseif path:find("Meme-Meme",1,true)then object:SetAttribute("ItemId",1431)
        else object.Name="Galaxy Empyrean Kitsune Fruit"end
        Instance.new("Part",object).Name="Handle"
        table.insert(originalObjects,object)
        return {object}
    end
    local function exists(path)
        return path=="codex_fruit_studio/models/Arcsteel Magnet.rbxm"
            or path=="codex_fruit_studio/models/Meme-Meme.rbxm"
            or path=="codex_fruit_studio/models/Empyrean (Kitsune)-Empyrean (Kitsune).rbxm"
    end
    local saved
    local env
    env=setmetatable({
        game=fake,isfile=exists,getcustomasset=function(path)return path end,
        readfile=function(path)assert(path=="blox-catalog-sim-v12.6.lua");return bundleSource end,
        writefile=function(path,value)assert(path=="blox-catalog-fruit-skin-audit-0.json");saved=value end,
        task={wait=function()end},
        loadstring=function(code,name)local fn,err=compile(code,name);return fn and setfenv(fn,env),err end,
    },{__index=getfenv()})
    local ok,report=pcall(setfenv(assert(compile(probeSource)),env))
    character:Destroy();backpack:Destroy()
    assert(ok,report)
    assert(report.complete and report.processed==134)
    assert(#report.categories.Fruits==47 and #report.categories["Fruit Skins"]==87)
    local byId={}
    for _,rows in pairs(report.categories)do for _,row in ipairs(rows)do byId[row.id]=row end end
    assert(byId["1431"].status=="ModelLoaded" and byId["1525"].status=="ModelLoaded")
    assert(byId["1041"].status=="ModelRejected" and byId["1041"].error:find("contains Galaxy",1,true))
    assert(byId["1516"].status=="MissingModel")
    assert(byId["1431"].animationStatus=="Missing" and byId["1525"].animationStatus=="Missing")
    local metadata=0
    for _,row in pairs(byId)do if row.status=="MetadataOnly"then metadata+=1 end end
    assert(metadata==53 and saved)
    for _,object in ipairs(originalObjects)do assert(object.Parent==nil and #object:GetChildren()==0)end
    assert(not workspace:FindFirstChild("BloxCatalogFruitSkinAudit"))
    return "Fruit/skin audit grouping, model states, metadata-only rows, missing animation and cleanup assertions passed"
end
