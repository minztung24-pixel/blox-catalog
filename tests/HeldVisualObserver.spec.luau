return function(source, mode)
    mode=mode or "visuals"
    local character=Instance.new("Model")
    local gui=Instance.new("Folder")
    local catalog=Instance.new("ScreenGui",gui);catalog.Name="BloxCatalogSim"
    local panel=Instance.new("Frame",catalog);panel.Name="Panel"
    local status=Instance.new("TextLabel",panel);status.Name="Status"
    local log=Instance.new("BindableEvent")
    local clock,current=0,nil
    local function equip(id)
        if current then current.Parent=nil;current:Destroy()end
        current=Instance.new("Tool");current.Name="Fixture"
        current.ToolTip="Fruits";current:SetAttribute("ItemId",id);current:SetAttribute("BloxCatalogOwned",true)
        status.Text="Equip "..id
        local handle=Instance.new("Part",current);handle.Name="Handle";handle.CFrame=CFrame.new(2,3,4)
        local eyes=Instance.new("MeshPart",current);eyes.Name="Eyes";eyes.CFrame=CFrame.new(7,3,4)
        Instance.new("Bone",eyes).Name="EyeBone"
        local emitter=Instance.new("ParticleEmitter",eyes);emitter.Enabled=false;emitter.Rate=25
        emitter:SetAttribute("EmitCount",7)
        current.Parent=character
    end
    local targets={1422,1447,884,1047,1394,1427,1389,1430,814}
    equip(mode=="motion" and targets[1] or 1525)
    local Content={GetAssetFetchStatus=function()return Enum.AssetFetchStatus.Success end}
    local fake={PlaceId=0,GameId=994732206}
    function fake:GetService(name)
        if name=="Players"then return {LocalPlayer={Character=character,FindFirstChildOfClass=function(_,class)
            assert(class=="PlayerGui");return gui
        end}}
        elseif name=="ContentProvider"then return Content
        elseif name=="LogService"then return {MessageOut=log.Event}end
        return game:GetService(name)
    end
    local saved
    local fn=assert(loadstring(source))
    setfenv(fn,setmetatable({game=fake,workspace={CurrentCamera=nil},os={clock=function()return clock end},
        task={wait=function()
            clock+=1
            if mode=="motion"then
                if clock%8==0 and targets[clock/8+1]then equip(targets[clock/8+1])end
            elseif clock==7 then equip(1422)elseif clock==15 then equip(1391)end
        end},writefile=function(path,data)
            assert(path==(mode=="motion" and "blox-catalog-motion-check-0.json" or "blox-fruits-held-visuals-0.json"));saved=data
        end,
    },{__index=getfenv()}))
    local ok,report=pcall(fn,mode)
    character:Destroy();log:Destroy();gui:Destroy()
    assert(ok,report)
    if mode=="motion"then
        assert(report.complete and report.targetsComplete and #report.fruits==8 and #report.missingTargets==0 and clock<180)
        assert(#report.catalogStatuses==9,"Capture Catalog errors even when no target Tool exists")
        for _,row in ipairs(report.fruits)do
            assert(row.itemId~=1422,"Gas is outside this check")
            assert(#row.samples==4 and row.samples[4].held)
            assert(#row.samples[4].poses==1 and row.localVisual)
        end
        assert(saved)
        return "Motion observer target, held-state, Gas exclusion and Catalog-status assertions passed"
    end
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
