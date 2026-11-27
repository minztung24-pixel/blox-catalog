return function(FruitArchive,FruitModels)
    local Http=game:GetService("HttpService")
    local files,models={},{}
    local writes=0
    local ops={
        exists=function(path)return files[path]~=nil end,
        read=function(path)return assert(files[path],"Missing fixture file")end,
        write=function(path,value)files[path]=value;writes+=1 end,
        uri=function(path)return path end,
        objects=function(path)return {assert(models[path]):Clone()}end,
        export=function(root,path)
            local copy=root:Clone();copy:SetAttribute("ItemId",nil)
            copy.Handle.ParticleEmitter.Speed=NumberRange.new(1.30164,2.73344)
            models[path]=copy;files[path]="fixture model bytes"
        end,
    }
    local holder=Instance.new("Folder")
    local source=Instance.new("Tool",holder);source:SetAttribute("ItemId",1516);source:SetAttribute("BloxCatalogOwned",true)
    source:SetAttribute("UID","private-runtime-value")
    local handle=Instance.new("Part",source);handle.Name="Handle"
    Instance.new("SpecialMesh",handle)
    local fx=Instance.new("ParticleEmitter",handle);fx.Speed=NumberRange.new(1.3016364574432374,2.7334365844726564)
    local item={id="1516",name="Fixture",category="Fruits"}
    local archive=FruitArchive.new(ops)
    local ok,message=pcall(function()
        assert(not archive:available(item))
        assert(archive:save(item,source))
        assert(archive:available(item))
        archive:close()
        archive=FruitArchive.new(ops)
        local restored=assert(archive:load(item))
        assert(restored:GetAttribute("ItemId")==1516 and not restored:GetAttribute("UID"))
        assert(restored.Handle.ParticleEmitter.Speed==fx.Speed,"Repair exporter rounding from measured source")
        restored:Destroy()
        if FruitModels then
            local cache=FruitModels.new(function()return false end)
            cache.archive=FruitArchive.new(ops)
            assert(cache:available(item),"Saved capture must enable the card before Equip")
            local imported=assert(cache:load(item))
            assert(imported.Parent and cache.archived[item.id]and imported:GetAttribute("ItemId")==1516,"Cold cache imports verified captures")
            cache:close()
            assert(cache.archive.closed,"Closing Catalog closes the archive")
        end
        assert(source:GetAttribute("UID")=="private-runtime-value"and source.Parent==holder,"Never mutate capture source")
        local index=Http:JSONDecode(files["blox-catalog-captured-fruits-v1.json"])
        local entry=index.entries[item.id]
        models[entry.file].Handle.Size=Vector3.one*99
        assert(not archive:load(item)and not archive:available(item),"Corrupt geometry must fail closed")
        index.entries[item.id].file="../original.rbxm"
        files["blox-catalog-captured-fruits-v1.json"]=Http:JSONEncode(index)
        files["blox-catalog-captured-fruits-v1.backup.json"]=nil
        archive:close();archive=FruitArchive.new(ops)
        assert(not archive:available(item),"Reject paths outside the capture namespace")
        local before=writes
        archive:enqueue(item,source);archive:close();task.wait(.7)
        assert(writes==before,"Closing cancels queued writes")
        assert(not files["codex_fruit_studio/models/Fixture.rbxm"],"Never replace original model files")
    end)
    archive:close();holder:Destroy()
    for _,model in pairs(models)do model:Destroy()end
    assert(ok,message)
    return "Fruit archive persistence assertions passed"
end
