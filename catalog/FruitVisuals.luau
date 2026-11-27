local FruitVisuals={}
local props={
    Tool={"Grip","TextureId","ToolTip","RequiresHandle","CanBeDropped","Enabled","ManualActivationOnly"},
    BasePart={"CFrame","Size","Transparency","Color","Material","MaterialVariant","Reflectance","LocalTransparencyModifier"},
    MeshPart={"MeshId","TextureID","DoubleSided"},
    SpecialMesh={"MeshId","TextureId","Scale","Offset","VertexColor","MeshType"},
    Decal={"Texture","Transparency","Color3","Face"},
    SurfaceAppearance={"ColorMap","NormalMap","RoughnessMap","MetalnessMap","AlphaMode"},
    Attachment={"CFrame"},Bone={"Transform"},JointInstance={"C0","C1","Part0","Part1"},Motor6D={"Transform"},
    WeldConstraint={"Part0","Part1","Enabled"},Animation={"AnimationId"},
    ParticleEmitter={"Texture","Enabled","Rate","TimeScale","Lifetime","Speed","Transparency","Size","Color","LightEmission","LightInfluence"},
    Beam={"Texture","Enabled","Attachment0","Attachment1","Width0","Width1","Color","Transparency"},
    Trail={"Texture","Enabled","Attachment0","Attachment1","Lifetime","Color","Transparency"},
    GuiObject={"Position","Size","AnchorPoint","Rotation","Visible","BackgroundTransparency","BackgroundColor3","ZIndex"},
    ImageLabel={"Image","ImageTransparency","ImageColor3","ImageRectOffset","ImageRectSize"},
    ImageButton={"Image","ImageTransparency","ImageColor3"},
    SurfaceGui={"Enabled","AlwaysOnTop","Adornee","Face"},BillboardGui={"Enabled","AlwaysOnTop","Adornee","StudsOffset"},
    Light={"Enabled","Color","Brightness"},
}
local function nodes(root)
    local result={root}
    for _,node in ipairs(root:GetDescendants())do table.insert(result,node)end
    assert(#result<=3001,"Fruit exceeds archive node limit")
    return result
end
local function encode(value,indices)
    local kind=typeof(value)
    if kind=="Instance"then return assert(indices[value],"External archive reference")
    elseif kind=="CFrame"then return {value:GetComponents()}
    elseif kind=="Vector3"then return {value.X,value.Y,value.Z}
    elseif kind=="Vector2"then return {value.X,value.Y}
    elseif kind=="UDim"then return {value.Scale,value.Offset}
    elseif kind=="UDim2"then return {value.X.Scale,value.X.Offset,value.Y.Scale,value.Y.Offset}
    elseif kind=="Color3"then return {value.R,value.G,value.B}
    elseif kind=="Content"then
        assert(value.SourceType==Enum.ContentSourceType.Uri or value.SourceType==Enum.ContentSourceType.None,"Archive cannot preserve object-backed texture content")
        return value.Uri or ""
    elseif kind=="NumberRange"then return {value.Min,value.Max}
    elseif kind=="NumberSequence"or kind=="ColorSequence"then
        local points={}
        for _,point in ipairs(value.Keypoints)do table.insert(points,{point.Time,encode(point.Value,indices),kind=="NumberSequence"and point.Envelope or nil})end
        return points
    elseif kind=="EnumItem"then return tostring(value)
    elseif kind=="nil"then return "<nil>"
    elseif kind=="string"or kind=="boolean"or kind=="number"then return value end
    error("Unsupported archive value: "..kind)
end
local function read(root)
    local all=nodes(root)
    local indices,shape,values,overrides={},{},{},{}
    for i,node in ipairs(all)do indices[node]=i end
    for i,node in ipairs(all)do shape[i]={class=node.ClassName,name=node.Name,parent=indices[node.Parent]or 0}end
    for i,node in ipairs(all)do
        values[i]={}
        for class,fields in pairs(props)do if node:IsA(class)then
            for _,property in ipairs(fields)do
                -- SurfaceAppearance's legacy map strings require PluginSecurity; Content maps are publicly readable.
                local value
                if node:IsA("SurfaceAppearance")and property:match("Map$")then value=node[property.."Content"]
                else value=node[property]end
                values[i][property]=encode(value,indices)
                local kind=typeof(value)
                if kind=="NumberRange"or kind=="NumberSequence"or kind=="ColorSequence"then
                    table.insert(overrides,{node=i,property=property,kind=kind,value=encode(value,indices)})
                end
            end
        end end
    end
    return {shape=shape,values=values},overrides
end
local function equivalent(a,b)
    if type(a)~=type(b)then return false end
    if type(a)=="number"then return math.abs(a-b)<=.000001 end
    if type(a)~="table"then return a==b end
    for key,value in pairs(a)do if not equivalent(value,b[key])then return false end end
    for key in pairs(b)do if a[key]==nil then return false end end
    return true
end
function FruitVisuals.snapshot(root)return (read(root))end
function FruitVisuals.differences(a,b)
    return equivalent(a,b)and {}or {"Archive visual/rig properties differ"}
end
function FruitVisuals.metadata(root)
    local expected,overrides=read(root)
    local id=tostring(root:GetAttribute("ItemId")or "")
    assert(id:match("^%d+$"),"Archive needs physical ItemId")
    return {schemaVersion=1,id=id,expected=expected,overrides=overrides}
end
function FruitVisuals.restore(root,meta,id)
    assert(type(meta)=="table"and meta.schemaVersion==1 and meta.id==id,"Archive ItemId mismatch")
    local all=nodes(root)
    local indices={}
    for i,node in ipairs(all)do indices[node]=i end
    assert(type(meta.expected)=="table"and type(meta.expected.shape)=="table"and #meta.expected.shape==#all,"Archive structure differs")
    for i,node in ipairs(all)do
        local shape=meta.expected.shape[i]
        assert(type(shape)=="table"and shape.class==node.ClassName and shape.name==node.Name
            and shape.parent==(indices[node.Parent]or 0),"Archive hierarchy/identity differs")
    end
    assert(type(meta.overrides)=="table"and #meta.overrides<=30000,"Invalid archive overrides")
    for _,entry in ipairs(meta.overrides)do
        local node=all[entry.node]
        local allowed=false
        if node then for class,fields in pairs(props)do
            if node:IsA(class)and table.find(fields,entry.property)then allowed=true;break end
        end end
        assert(allowed and typeof(node[entry.property])==entry.kind,"Invalid archive property repair")
        local value=entry.value
        if entry.kind=="NumberRange"then
            node[entry.property]=NumberRange.new(value[1],value[2])
        elseif entry.kind=="NumberSequence"then
            assert(#value<=64,"Too many sequence points")
            local points={}
            for _,point in ipairs(value)do table.insert(points,NumberSequenceKeypoint.new(point[1],point[2],point[3]))end
            node[entry.property]=NumberSequence.new(points)
        elseif entry.kind=="ColorSequence"then
            assert(#value<=64,"Too many sequence points")
            local points={}
            for _,point in ipairs(value)do table.insert(points,ColorSequenceKeypoint.new(point[1],Color3.new(table.unpack(point[2]))))end
            node[entry.property]=ColorSequence.new(points)
        else error("Unsupported archive repair")end
    end
    assert(equivalent(FruitVisuals.snapshot(root),meta.expected),"Archive lost visual/rig data")
    root:SetAttribute("ItemId",tonumber(id))
    root:SetAttribute("BloxCatalogOwned",true)
    return root
end
return FruitVisuals
