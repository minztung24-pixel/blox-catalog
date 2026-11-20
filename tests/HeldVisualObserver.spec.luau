return function(source)
    local character=Instance.new("Model")
    local log=Instance.new("BindableEvent")
    local clock,current=0,nil
    local function equip(id)
        if current then current.Parent=nil;current:Destroy()end
        current=Instance.new("Tool");current.Name="Fixture"
        current.ToolTip="Fruits";current:SetAttribute("ItemId",id);current:SetAttribute("BloxCatalogOwned",true)
        local handle=Instance.new("Part",current);handle.Name="Handle";handle.CFrame=CFrame.new(2,3,4)
        local eyes=Instance.new("MeshPart",current);eyes.Name="Eyes";eyes.CFrame=CFrame.new(7,3,4)
        Instance.new("Bone",eyes).Name="EyeBone"
        local emitter=Instance.new("ParticleEmitter",eyes);emitter.Enabled=false;emitter.Rate=25
        emitter:SetAttribute("EmitCount",7)
        current.Parent=character
    end
    equip(1525)
    local Content={GetAssetFetchStatus=function()return Enum.AssetFetchStatus.Success end}
    local fake={PlaceId=0,GameId=994732206}
    function fake:GetService(name)
        if name=="Players"then return {LocalPlayer={Character=character}}
        elseif name=="ContentProvider"then return Content
        elseif name=="LogService"then return {MessageOut=log.Event}end
        return game:GetService(name)
    end
    local saved
    local fn=assert(loadstring(source))
    setfenv(fn,setmetatable({game=fake,workspace={CurrentCamera=nil},os={clock=function()return clock end},
        task={wait=function()
            clock+=1
            if clock==7 then equip(1422)elseif clock==15 then equip(1391)end
        end},writefile=function(path,data)
            assert(path=="blox-fruits-held-visuals-0.json");saved=data
        end,
    },{__index=getfenv()}))
    local ok,report=pcall(fn,"visuals")
    character:Destroy();log:Destroy()
    assert(ok,report)
    assert(report.complete and report.targetsComplete and #report.fruits==3 and clock<90)
    for _,row in ipairs(report.fruits)do
        local sample=row.samples[#row.samples]
        assert(sample.held and #row.samples==4 and #sample.poses==1)
        assert(sample.meshes[1].position.distanceFromHandle==5 and sample.meshes[1].transparency==0)
        assert(sample.effects[1].enabled==false and sample.effects[1].rate==25 and sample.effects[1].emitCount==7)
        assert(sample.effects[1].position.distanceFromHandle==5 and sample.poses[1].position)
    end
    assert(saved,"Persist the held samples for inspection")
    return "Held visual observer assertions passed"
end
