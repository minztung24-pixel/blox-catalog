-- Verified pose changes on these exact imported rigs; see docs/fruit-animation-validation.json.
local FruitAnimations={references={
    ["1411"]={signature="b084a610:29",originalId="rbxassetid://100716764466975",animationId="rbxassetid://15123685330"}, -- Spin
    ["1399"]={signature="3523854b:22",originalId="rbxassetid://78763341927414",animationId="rbxassetid://15123613404"}, -- Blade
    ["1402"]={signature="7de4dbe4:55",originalId="rbxassetid://123916780450655",animationId="rbxassetid://15123689268"}, -- Spring
    ["1397"]={signature="2ecd3777:54",originalId="rbxassetid://87174669415581",animationId="rbxassetid://15123595806"}, -- Bomb
    ["1400"]={signature="25095ae4:174",originalId="rbxassetid://90337525444547",animationId="rbxassetid://15123677932"}, -- Smoke
    ["1398"]={signature="cfca5a5a:154",originalId="rbxassetid://108171996739918",animationId="rbxassetid://15124220207"}, -- Spike
    ["1404"]={signature="d484bf3b:149",originalId="rbxassetid://92557992918502",animationId="rbxassetid://15123673019"}, -- Sand
    ["1395"]={signature="531b1bdd:79",originalId="rbxassetid://85473797801042",animationId="rbxassetid://15123618591"}, -- Dark
    ["1425"]={signature="afe45137:77",originalId="",animationId="rbxassetid://77885466312115"}, -- Eagle
    ["1407"]={signature="5a98bc81:47",originalId="rbxassetid://139348349272463",animationId="rbxassetid://15123640714"}, -- Light
    ["1396"]={signature="3514e101:99",originalId="rbxassetid://109351257940335",animationId="rbxassetid://15123668008"}, -- Rubber
    ["1412"]={signature="8b49a3f4:93",originalId="rbxassetid://111438700727499",animationId="rbxassetid://15123662036"}, -- Ghost
    ["1391"]={signature="331acd69:45",originalId="rbxassetid://116451105732247",animationId="rbxassetid://15123645682"}, -- Magma
    ["1408"]={signature="14a29ba8:63",originalId="rbxassetid://91553047104929",animationId="rbxassetid://15123643097"}, -- Love
    ["1403"]={signature="851c59df:113",originalId="rbxassetid://70644057708392",animationId="rbxassetid://15123681598"}, -- Spider
    ["1426"]={signature="2662b4b2:270",originalId="rbxassetid://125602647148821",animationId="rbxassetid://116828771482820"}, -- Creation
    ["1419"]={signature="f3992a44:22",originalId="rbxassetid://110296133369830",animationId="rbxassetid://15123679712"}, -- Sound
    ["1401"]={signature="f723e1ad:148",originalId="rbxassetid://110612702088317",animationId="rbxassetid://15123654553"}, -- Phoenix
    ["1406"]={signature="e9f8eb69:61",originalId="rbxassetid://90610310104520",animationId="rbxassetid://15123652069"}, -- Pain
    ["1416"]={signature="774b737e:52",originalId="rbxassetid://86482233160763",animationId="rbxassetid://15123587371"}, -- Blizzard
    ["1405"]={signature="bbeef6df:29",originalId="rbxassetid://116927061710230",animationId="rbxassetid://15123633312"}, -- Gravity
    ["1418"]={signature="63f30c83:68",originalId="rbxassetid://130603473374710",animationId="rbxassetid://15123648309"}, -- Mammoth
    ["1420"]={signature="a192ef7a:37",originalId="rbxassetid://80001241268158",animationId="rbxassetid://15694681122"}, -- T-Rex
    ["1417"]={signature="af10ce91:93",originalId="rbxassetid://78945929208351",animationId="rbxassetid://15123624401"}, -- Dough
    ["1413"]={signature="8a65d8e9:109",originalId="rbxassetid://125732165968983",animationId="rbxassetid://15123675904"}, -- Shadow
    ["1409"]={signature="b3a04f4f:49",originalId="rbxassetid://79809986694708",animationId="rbxassetid://15123616275"}, -- Control
    ["1415"]={signature="af733ecf:51",originalId="rbxassetid://125702468812458",animationId="rbxassetid://11911905519"}, -- Spirit
    ["1423"]={signature="1620d10f:157",originalId="rbxassetid://111861961607052",animationId="rbxassetid://15487764876"}, -- Kitsune
    ["1424"]={signature="12796b03:128",originalId="rbxassetid://139168229602923",animationId="rbxassetid://115276580506154"}, -- Yeti
    ["1422"]={signature="1e654c15:154",originalId="rbxassetid://121824149217894",animationId="rbxassetid://118054805452821"}, -- Gas
}}

local function relative(node,root)
    if not node then return "<nil>" end
    local parts={}
    while node and node~=root do table.insert(parts,1,node.Name);node=node.Parent end
    return node==root and table.concat(parts,"/") or "<external>"
end
function FruitAnimations.signature(root)
    local lines={}
    for _,node in ipairs(root:GetDescendants())do
        if node:IsA("BasePart") or node:IsA("Bone") or node:IsA("Motor6D") or node:IsA("AnimationController")then
            local row=node.ClassName..":"..relative(node,root)
            if node:IsA("MeshPart")then row=row..":"..node.MeshId end
            if node:IsA("Motor6D")then row=row..":"..relative(node.Part0,root)..":"..relative(node.Part1,root) end
            table.insert(lines,row)
        end
    end
    table.sort(lines)
    local text=table.concat(lines,"\n")
    local hash=2166136261
    for i=1,#text do
        hash=bit32.bxor(hash,text:byte(i))
        hash=(hash*403+bit32.lshift(hash,24))%4294967296
    end
    return string.format("%08x:%d",hash,#lines)
end

function FruitAnimations.apply(tool,item)
    local reference=FruitAnimations.references[item.id]
    if item.category~="Fruits" or not reference then return false end
    local fruit=tool:FindFirstChild("Fruit")
    if not fruit or not fruit:FindFirstChildOfClass("AnimationController") then return false end
    local animation=fruit:FindFirstChild("Idle") or fruit:FindFirstChild("Animation")
    if animation and not animation:IsA("Animation") then return false end
    if (animation and animation.AnimationId or "")~=reference.originalId
        or FruitAnimations.signature(tool)~=reference.signature then return false end
    if not animation then animation=Instance.new("Animation",fruit);animation.Name="Idle" end
    animation.AnimationId=reference.animationId
    return true
end

return FruitAnimations

