return function(FruitVisuals)
    local folder=Instance.new("Folder")
    local source=Instance.new("Tool",folder);source.Name="Fixture";source:SetAttribute("ItemId",1516);source:SetAttribute("UID","do-not-export")
    local part=Instance.new("Part",source);part.Name="Handle"
    local fx=Instance.new("ParticleEmitter",part)
    fx.Speed=NumberRange.new(1.3016364574432374,2.7334365844726564)
    fx.Size=NumberSequence.new(2.2874526977539064)
    fx.Color=ColorSequence.new(Color3.fromRGB(12,34,56),Color3.fromRGB(78,90,123))
    local copies={}
    local ok,message=pcall(function()
        local meta=FruitVisuals.metadata(source)
        assert(meta.id=="1516"and not game:GetService("HttpService"):JSONEncode(meta):find("do-not-export",1,true),"Store physical identity, not runtime UID")
        local copy=source:Clone();copy.Parent=folder;table.insert(copies,copy)
        copy:SetAttribute("ItemId",nil)
        copy.Handle.ParticleEmitter.Speed=NumberRange.new(1.30164,2.73344)
        copy.Handle.ParticleEmitter.Size=NumberSequence.new(2.28745)
        copy.Handle.ParticleEmitter.Color=ColorSequence.new(Color3.new())
        FruitVisuals.restore(copy,meta,"1516")
        assert(copy:GetAttribute("ItemId")==1516)
        assert(copy.Handle.ParticleEmitter.Speed==fx.Speed and copy.Handle.ParticleEmitter.Size==fx.Size and copy.Handle.ParticleEmitter.Color==fx.Color,"Restore observed sequence/range values exactly")
        assert(#FruitVisuals.differences(FruitVisuals.snapshot(source),FruitVisuals.snapshot(copy))==0)
        assert(not pcall(FruitVisuals.restore,copy,meta,"1525"),"Never apply base metadata to another physical skin")
        copy.Handle.Size=Vector3.one*99
        assert(not pcall(FruitVisuals.restore,copy,meta,"1516"),"Reject geometry loss rather than accepting a partial export")
        local forged=game:GetService("HttpService"):JSONDecode(game:GetService("HttpService"):JSONEncode(meta))
        forged.overrides[1].property="Parent"
        assert(not pcall(FruitVisuals.restore,copy,forged,"1516")and copy.Parent==folder,"Metadata cannot reparent instances")
        local branch=Instance.new("Folder",source)
        local leaf=Instance.new("Folder",branch)
        meta=FruitVisuals.metadata(source)
        leaf.Parent=source
        assert(not pcall(FruitVisuals.restore,source,meta,"1516"),"Reject hierarchy loss even when flat node order is unchanged")
    end)
    folder:Destroy()
    assert(ok,message)
    return "Fruit archive metadata assertions passed"
end
