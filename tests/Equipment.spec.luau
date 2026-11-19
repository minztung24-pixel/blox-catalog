return function(Equipment)
    local root = Instance.new("Folder")
    local source = Instance.new("Tool"); source.Name = "Original fixture"; source.Parent = root
    game:GetService("CollectionService"):AddTag(source, "CatalogSpecComponent")
    local handle = Instance.new("Part"); handle.Name = "Handle"; handle.Anchored = true; handle.Parent = source
    local accent = Instance.new("Part"); accent.Name = "Accent"; accent.Anchored = true; accent.Parent = source
    local rigPart = Instance.new("Part"); rigPart.Name = "RigPart"; rigPart.Parent = source
    local joint = Instance.new("Motor6D"); joint.Part0 = handle; joint.Part1 = rigPart; joint.Parent = handle
    local code = Instance.new("ModuleScript"); code.Parent = source
    local remote = Instance.new("RemoteEvent"); remote.Parent = source
    local external = Instance.new("Part"); external.Parent = root
    local unsafe = Instance.new("WeldConstraint"); unsafe.Part0 = handle; unsafe.Part1 = external; unsafe.Parent = source
    local ok, err = pcall(function()
        local tool = assert(Equipment.clone(source, {id = "1393", name = "Buddha", category = "Fruits"}))
        assert(tool:IsA("Tool") and tool:GetAttribute("BloxCatalogOwned") == true)
        assert(not tool:FindFirstChildWhichIsA("LuaSourceContainer", true))
        assert(not tool:FindFirstChildWhichIsA("RemoteEvent", true))
        assert(not tool.Handle.Anchored and not tool.Handle.CanCollide and not tool.Enabled)
        assert(tool.ManualActivationOnly and tool.RequiresHandle and tool:FindFirstChild("Handle"))
        assert(#game:GetService("CollectionService"):GetTags(tool) == 0, "Game component tags must not activate on local clones")
        for _, node in ipairs(tool:GetDescendants()) do
            if node:IsA("WeldConstraint") then
                assert(node.Part0:IsDescendantOf(tool) and node.Part1:IsDescendantOf(tool), "Clones must not weld the player to external objects")
                assert(node.Part1.Name ~= "RigPart", "Existing rig joints must not be frozen by redundant welds")
            end
        end
        assert(source:FindFirstChildWhichIsA("ModuleScript") and handle.Anchored, "Source must stay intact")
        tool:Destroy()
        assert(Equipment.clone(nil, {id = "1", name = "Missing", category = "Fruits"}) == nil, "An icon must not be passed off as a model")
    end)
    root:Destroy()
    assert(ok, err)
    return "Equipment assertions passed: clean local Tool, preserved source, safe welds, explicit missing model"
end
