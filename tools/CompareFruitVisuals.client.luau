-- Compare private copies only. Never equip, play scripts/animations, or invoke game remotes.
assert(game.GameId==994732206,"Run in the original Blox Fruits experience")
assert(type(readfile)=="function" and type(listfiles)=="function" and type(getcustomasset)=="function" and type(writefile)=="function","Run in Potassium")
local Http=game:GetService("HttpService")
local Content=game:GetService("ContentProvider")
local source=readfile("blox-catalog-sim-v12.lua")
local replacements
source,replacements=source:gsub("return UI%.start%(%)%s*$","return {Equipment=Equipment,Catalog=Catalog}")
assert(replacements==1,"Expected the standalone client; no UI was started")
local modules=assert(loadstring(source,"VisualAuditModules"))()
local good={['1424']=true,['1042']=true,['1525']=true,['1413']=true,['1408']=true,['1404']=true}
local report={schemaVersion=1,gameId=game.GameId,placeId=game.PlaceId,placeVersion=game.PlaceVersion,
    complete=false,models={},assets={},limits={},scope="Source-file versus sanitized-clone parity; no claim of current native visual parity"}
local output="blox-fruits-visual-parity-"..game.PlaceId..".json"
local props={
    BasePart={"Transparency","Color","Material","MaterialVariant","Reflectance","LocalTransparencyModifier"},
    MeshPart={"MeshId","TextureID","DoubleSided"},
    SpecialMesh={"MeshId","TextureId","Scale","Offset","VertexColor"},
    Decal={"Texture","Transparency","Color3","Face"},
    SurfaceAppearance={"ColorMap","NormalMap","RoughnessMap","MetalnessMap","AlphaMode"},
    Attachment={"CFrame"},Bone={"Transform"},Motor6D={"C0","C1","Transform","Part0","Part1"},
    ParticleEmitter={"Texture","Enabled","Rate","TimeScale","Lifetime","Speed","Transparency","Size","Color","LightEmission","LightInfluence"},
    Beam={"Texture","Enabled","Attachment0","Attachment1","Width0","Width1","Color","Transparency"},
    Trail={"Texture","Enabled","Attachment0","Attachment1","Lifetime","Color","Transparency"},
    ImageLabel={"Image","Visible","ImageTransparency","ImageColor3","ImageRectOffset","ImageRectSize"},
    ImageButton={"Image","Visible","ImageTransparency","ImageColor3"},
    SurfaceGui={"Enabled","AlwaysOnTop","Adornee","Face"},BillboardGui={"Enabled","AlwaysOnTop","Adornee","StudsOffset"},
    Light={"Enabled","Color","Brightness"},
}
local contentProperties={MeshId=true,TextureID=true,TextureId=true,Texture=true,ColorMap=true,NormalMap=true,RoughnessMap=true,MetalnessMap=true,Image=true}
local preloadNodes={}
local temporaryImages={}
local assetIndex={}
local function relative(node,root)
    if not node then return "<nil>"end
    local names={}
    while node and node~=root do table.insert(names,1,node.Name);node=node.Parent end
    return node==root and table.concat(names,"/") or "<external>"
end
local function encode(value,root)
    local kind=typeof(value)
    if kind=="Instance"then return relative(value,root)
    elseif kind=="CFrame"then return {value:GetComponents()}
    elseif kind=="Vector3"then return {value.X,value.Y,value.Z}
    elseif kind=="Vector2"then return {value.X,value.Y}
    elseif kind=="Color3"then return {value.R,value.G,value.B}
    elseif kind=="NumberRange"then return {value.Min,value.Max}
    elseif kind=="NumberSequence" or kind=="ColorSequence"then
        local points={}
        for _,p in ipairs(value.Keypoints)do table.insert(points,{p.Time,encode(p.Value,root),kind=="NumberSequence" and p.Envelope or nil})end
        return points
    elseif kind=="EnumItem"then return tostring(value)
    elseif kind=="number" or kind=="string" or kind=="boolean"then return value end
    return tostring(value)
end
local function fetchStatus(id)
    local ok,status=pcall(Content.GetAssetFetchStatus,Content,id)
    return ok and tostring(status) or "StatusUnavailable"
end
local function snapshot(root,collectAssets)
    local row={values={},classes={},scripts={},sounds={},tags={},readErrors={}}
    local nodes={root}
    for _,node in ipairs(root:GetDescendants())do table.insert(nodes,node)end
    for _,node in ipairs(nodes)do
        local path=relative(node,root)
        row.classes[node.ClassName]=(row.classes[node.ClassName] or 0)+1
        for _,tag in ipairs(node:GetTags())do table.insert(row.tags,path..":"..tag)end
        if node:IsA("LuaSourceContainer")then table.insert(row.scripts,path)end
        if node:IsA("Sound")then table.insert(row.sounds,path)end
        local hasContent,unsupportedContent=false,false
        for class,properties in pairs(props)do
            if node:IsA(class)then
                for _,property in ipairs(properties)do
                    local ok,value=pcall(function()return node[property]end)
                    if ok then
                        local key=node.ClassName..":"..path..":"..property
                        row.values[key]=row.values[key] or {}
                        table.insert(row.values[key],Http:JSONEncode(encode(value,root)))
                        if collectAssets and contentProperties[property] and type(value)=="string" and value~=""then
                            hasContent=true
                            local asset=assetIndex[value]
                            if not asset then
                                asset={id=value,before=fetchStatus(value),uses={}}
                                assetIndex[value]=asset;table.insert(report.assets,asset)
                            end
                            if #asset.uses<12 then table.insert(asset.uses,{file=root:GetAttribute("VisualAuditFile"),path=path,property=property})end
                            if not value:match("^rbxassetid://%d+$") and not value:match("^rbxasset://")then unsupportedContent=true end
                        end
                    else table.insert(row.readErrors,path..":"..property)end
                end
            end
        end
        if collectAssets and hasContent and not unsupportedContent then table.insert(preloadNodes,node)end
    end
    for _,values in pairs(row.values)do table.sort(values)end
    table.sort(row.tags)
    return row
end
local function equivalent(a,b)
    if type(a)~=type(b)then return false end
    if type(a)=="number"then return math.abs(a-b)<=0.000001 end
    if type(a)~="table"then return a==b end
    for key,value in pairs(a)do if not equivalent(value,b[key])then return false end end
    for key in pairs(b)do if a[key]==nil then return false end end
    return true
end
local function differences(before,after)
    local changed,keys={},{}
    for key in pairs(before.values)do keys[key]=true end
    for key in pairs(after.values)do keys[key]=true end
    for key in pairs(keys)do
        local a,b=before.values[key] or {},after.values[key] or {}
        local same=#a==#b
        for i=1,#a do
            if not b[i] or not equivalent(Http:JSONDecode(a[i]),Http:JSONDecode(b[i]))then same=false;break end
        end
        if not same then table.insert(changed,{key=key,before=a,after=b})end
    end
    table.sort(changed,function(a,b)return a.key<b.key end)
    return changed
end
local function selfCheck()
    local folder=Instance.new("Folder")
    local tool=Instance.new("Tool",folder)
    local handle=Instance.new("Part",tool);handle.Name="Handle"
    local emitter=Instance.new("ParticleEmitter",handle);emitter.Enabled=false;emitter.Rate=7
    Instance.new("Attachment",handle).Name="ProbeAttachment"
    Instance.new("LocalScript",tool)
    local clone
    local ok,err=pcall(function()
        clone=assert(modules.Equipment.clone(tool,{id="0",name="Probe",category="Fruits"}))
        assert(#differences(snapshot(tool),snapshot(clone))==0,"Visual properties must survive the fixture clone")
        clone.Handle.ProbeAttachment.CFrame=CFrame.new(0.00000001,0,0)
        assert(#differences(snapshot(tool),snapshot(clone))==0,"Ignore engine float normalization")
        clone.Handle.ProbeAttachment.CFrame=CFrame.new(.1,0,0)
        assert(#differences(snapshot(tool),snapshot(clone))>0,"Detect actual attachment movement")
        clone.Handle.ProbeAttachment.CFrame=CFrame.new()
        clone.Handle.ParticleEmitter.Enabled=true
        assert(#differences(snapshot(tool),snapshot(clone))>0,"Comparator must detect changed FX")
        assert(not emitter.Enabled and tool:FindFirstChildOfClass("LocalScript"),"Leave source behavior untouched")
        assert(not clone:FindFirstChildOfClass("LocalScript"),"Never run source scripts")
    end)
    if clone then clone:Destroy()end
    folder:Destroy();assert(ok,err)
end
selfCheck()
local folder=Instance.new("Folder")
local started=os.clock()
local ok,failure=pcall(function()
    local files=listfiles("codex_fruit_studio/models")
    table.sort(files)
    for _,path in ipairs(files)do
        local file=path:gsub("\\","/"):match("([^/]+%.rbxm)$")
        if not file or file:find("..",1,true)then continue end
        if #report.models>=80 or os.clock()-started>100 then report.limits.models=true;break end
        local row={file=file,matches={}}
        for _,item in ipairs(modules.Catalog.databases.Fruits)do
            if file==item.storageKey..".rbxm" or file==item.name..".rbxm"then
                table.insert(row.matches,{itemId=item.id,name=item.name,userConfirmedGood=good[item.id]==true})
            end
        end
        local objects,clone
        local passed,err=pcall(function()
            objects=game:GetObjects(getcustomasset("codex_fruit_studio/models/"..file))
            assert(type(objects)=="table" and #objects==1,"Expected one model root")
            local root=objects[1]
            assert(root.Parent==nil and #root:GetDescendants()<=3000,"Unexpected model contents")
            root.Parent=folder;root:SetAttribute("VisualAuditFile",file)
            row.rootName=root.Name;row.sourceItemId=root:GetAttribute("ItemId")
            local item=row.matches[1] or {itemId="0",name=root.Name}
            local before=snapshot(root,true)
            clone=assert(modules.Equipment.clone(root,{id=item.itemId,name=item.name,category="Fruits"}))
            local after=snapshot(clone)
            row.visualDifferences=differences(before,after)
            row.original={classes=before.classes,scripts=before.scripts,sounds=before.sounds,tags=before.tags,readErrors=before.readErrors}
            row.cloned={classes=after.classes,scripts=after.scripts,sounds=after.sounds,tags=after.tags,readErrors=after.readErrors}
        end)
        if clone then clone:Destroy()end
        if not passed then
            row.error=tostring(err)
            if type(objects)=="table"then for _,root in ipairs(objects)do if typeof(root)=="Instance"then root:Destroy()end end end
        end
        table.insert(report.models,row)
        writefile(output,Http:JSONEncode(report))
        task.wait()
    end
    local finished=false
    -- The first audit left PBR maps unrequested; fetch those image dependencies explicitly.
    for _,asset in ipairs(report.assets)do
        for _,use in ipairs(asset.uses)do
            if use.property:match("Map$") and asset.id:match("^rbxassetid://%d+$")then
                local image=Instance.new("ImageLabel");image.Image=asset.id
                table.insert(temporaryImages,image);table.insert(preloadNodes,image)
                asset.mapImagePreload=true;break
            end
        end
    end
    report.preload={nodes=#preloadNodes,completed=false,callbacks={}}
    local request
    if #preloadNodes>0 then
        request=task.spawn(function()
            local passed,err=pcall(Content.PreloadAsync,Content,preloadNodes,function(uri,status)
                report.preload.callbacks[tostring(uri)]=tostring(status)
            end)
            if not passed then report.preload.error=tostring(err)end
            finished=true
        end)
        local deadline=os.clock()+20
        while not finished and os.clock()<deadline do task.wait(.1)end
        if not finished then pcall(task.cancel,request);report.limits.preload=true end
    else finished=true end
    report.preload.completed=finished
    for _,asset in ipairs(report.assets)do asset.after=fetchStatus(asset.id)end
end)
folder:Destroy()
for _,image in ipairs(temporaryImages)do image:Destroy()end
report.numericTolerance=0.000001
report.complete=ok and next(report.limits)==nil
report.modelErrors=0;report.comparisonReadErrors=0
for _,row in ipairs(report.models)do
    if row.error then report.modelErrors+=1 end
    if row.original then report.comparisonReadErrors+=#row.original.readErrors+#row.cloned.readErrors end
end
report.conclusiveVisualComparison=report.complete and report.modelErrors==0 and report.comparisonReadErrors==0
if not ok then report.error=tostring(failure)end
report.elapsed=os.clock()-started
writefile(output,Http:JSONEncode(report))
print("Fruit visual parity saved: "..output.." | models="..#report.models.." | complete="..tostring(report.complete))
return report
