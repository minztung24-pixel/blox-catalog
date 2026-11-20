return function(probeSource,bundleSource)
    local actualGame=game
    local Content={}
    function Content:GetAssetFetchStatus()return Enum.AssetFetchStatus.Success end
    function Content:PreloadAsync(nodes,callback)
        assert(#nodes>0,"Expected typed asset instances")
        local image=false
        for _,node in ipairs(nodes)do if node:IsA("ImageLabel") and node.Image=="rbxassetid://1"then image=true end end
        assert(image,"Explicitly fetch SurfaceAppearance map images")
        callback("rbxassetid://1",Enum.AssetFetchStatus.Success)
    end
    local original
    local fake={GameId=994732206,PlaceId=0,PlaceVersion=0}
    function fake:GetService(name)return name=="ContentProvider" and Content or actualGame:GetService(name)end
    function fake:GetObjects()
        original=Instance.new("Tool");original.Name="Magma-Magma"
        local handle=Instance.new("Part",original);handle.Name="Handle"
        local emitter=Instance.new("ParticleEmitter",handle);emitter.Enabled=false;emitter.Texture="rbxassetid://1"
        local mesh=Instance.new("MeshPart",original);mesh.Name="Body"
        Instance.new("SurfaceAppearance",mesh).ColorMap="rbxassetid://1"
        Instance.new("LocalScript",original)
        Instance.new("Sound",original)
        return {original}
    end
    local writes={}
    local fn=assert(loadstring(probeSource))
    setfenv(fn,setmetatable({game=fake,
        readfile=function(path)assert(path=="blox-catalog-sim-v12.lua");return bundleSource end,
        listfiles=function()return {"codex_fruit_studio/models/Magma-Magma.rbxm"}end,
        getcustomasset=function(path)return path end,
        writefile=function(path,data)writes[path]=data end,
    },{__index=getfenv()}))
    local report=fn()
    assert(report.complete and report.conclusiveVisualComparison and #report.models==1)
    assert(#report.models[1].visualDifferences==0 and report.models[1].matches[1].itemId=="1391")
    assert(#report.models[1].original.scripts==1 and #report.models[1].cloned.scripts==0)
    assert(#report.models[1].original.sounds==1 and #report.models[1].cloned.sounds==0)
    assert(#report.assets==1 and report.preload.completed and report.assets[1].after==tostring(Enum.AssetFetchStatus.Success))
    assert(report.assets[1].mapImagePreload,"Record how PBR images were fetched")
    assert(original.Parent==nil and #original:GetChildren()==0,"Private imported copies must be destroyed")
    assert(writes["blox-fruits-visual-parity-0.json"],"Write a reusable report")
    return "Visual parity diagnostic assertions passed"
end
