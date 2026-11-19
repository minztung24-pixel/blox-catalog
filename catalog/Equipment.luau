local Equipment = {}

function Equipment.findExistingTool(player, item)
    local function normalized(name) return name:lower():gsub("%s", "") end
    local names = {}
    local suffix = item.category == "Fruits" and " Fruit" or ""
    names[normalized(item.name .. suffix)] = true
    names[normalized((item.storageKey or item.name) .. suffix)] = true
    local fallback
    for _, root in pairs({player:FindFirstChildOfClass("Backpack"), player.Character}) do
        for _, tool in ipairs(root:GetChildren()) do
            if tool:IsA("Tool") and not tool:GetAttribute("BloxCatalogOwned") and not tool:GetAttribute("ClientCatalogOwned") then
                local id = tool:GetAttribute("ItemId")
                if id ~= nil then
                    if tostring(id) == item.id then return tool end
                elseif names[normalized(tool.Name)] then fallback = fallback or tool end
            end
        end
    end
    return fallback
end

function Equipment.clone(source, item)
    if not source or not source.Parent or source:IsA("LuaSourceContainer") then return nil end
    local ok, clone = pcall(function() return source:Clone() end)
    if not ok or not clone then return nil end
    local CollectionService = game:GetService("CollectionService")
    local function clearTags(node)
        for _, tag in ipairs(CollectionService:GetTags(node)) do CollectionService:RemoveTag(node, tag) end
    end
    clearTags(clone)
    for _, node in ipairs(clone:GetDescendants()) do
        clearTags(node)
        if node:IsA("LuaSourceContainer") or node:IsA("RemoteEvent") or node:IsA("RemoteFunction")
            or node:IsA("ProximityPrompt") or node:IsA("ClickDetector") or node:IsA("BodyMover") or node:IsA("Sound") then
            node:Destroy()
        elseif node:IsA("JointInstance") or node:IsA("WeldConstraint") or node:IsA("NoCollisionConstraint") then
            if not node.Part0 or not node.Part1 or not node.Part0:IsDescendantOf(clone) or not node.Part1:IsDescendantOf(clone) then node:Destroy() end
        elseif node:IsA("Constraint") or node:IsA("Beam") or node:IsA("Trail") then
            for _, property in ipairs({"Attachment0", "Attachment1"}) do
                local attachment = node[property]
                if attachment and not attachment:IsDescendantOf(clone) then node:Destroy(); break end
            end
        end
    end
    local tool
    if clone:IsA("Tool") then tool = clone else tool = Instance.new("Tool"); clone.Parent = tool end
    local handle = tool:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        handle = tool:FindFirstChildWhichIsA("BasePart", true)
        if not handle then tool:Destroy(); return nil end
        handle.Name = "Handle"; handle.Parent = tool
    end
    local links, parts = {}, {}
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false; part.CanCollide = false; part.CanTouch = false; part.CanQuery = false; part.Massless = true
            table.insert(parts, part)
        elseif part:IsA("JointInstance") or part:IsA("WeldConstraint") or (part:IsA("Constraint") and not part:IsA("NoCollisionConstraint")) then
            local a, b
            if part:IsA("JointInstance") or part:IsA("WeldConstraint") then a, b = part.Part0, part.Part1
            else
                a = part.Attachment0 and part.Attachment0:FindFirstAncestorWhichIsA("BasePart")
                b = part.Attachment1 and part.Attachment1:FindFirstAncestorWhichIsA("BasePart")
            end
            if a and b then
                links[a] = links[a] or {}; table.insert(links[a], b)
                links[b] = links[b] or {}; table.insert(links[b], a)
            end
        end
    end
    local connected = {}
    local function visit(part)
        if connected[part] then return end
        connected[part] = true
        for _, neighbor in ipairs(links[part] or {}) do visit(neighbor) end
    end
    visit(handle)
    for _, part in ipairs(parts) do
        if not connected[part] then
            local weld = Instance.new("WeldConstraint"); weld.Part0 = handle; weld.Part1 = part; weld.Parent = part
            visit(part)
        end
    end
    tool.Name = item.name; tool.ToolTip = item.category
    tool.RequiresHandle = true; tool.CanBeDropped = false; tool.Enabled = false; tool.ManualActivationOnly = true
    tool:SetAttribute("BloxCatalogOwned", true); tool:SetAttribute("ItemId", tonumber(item.id))
    return tool
end

function Equipment.new(state, player, getSource, notify)
    local controller = {bindings = {}}
    function controller:remove(id)
        for _, connection in ipairs(self.bindings[id] or {}) do connection:Disconnect() end
        self.bindings[id] = nil
        local row = state.items[id]
        if row and row.tool then
            if row.tool:GetAttribute("BloxCatalogOwned") then row.tool:Destroy() end
            row.tool = nil
            row.equipped = false
        end
    end
    function controller:equip(item)
        local row = state.items[item.id]
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local backpack = player:FindFirstChildOfClass("Backpack")
        if not humanoid or humanoid.Health <= 0 or not backpack then return false, "Wait for your character to spawn" end
        local existing = Equipment.findExistingTool(player, item)
        if existing then
            if row and row.tool then
                if state.native then
                    local synced, message = state.native:sync(item, row.count, false, false)
                    if not synced then return false, message end
                end
                self:remove(item.id)
            end
            local ok, message = pcall(humanoid.EquipTool, humanoid, existing)
            if not ok or existing.Parent ~= character then return false, tostring(message or "Existing Tool did not equip") end
            return true, nil, "existing"
        end
        if not row or row.count < 1 then return false, "Add the item first" end
        local tool = row.tool
        if not tool or not tool.Parent then
            self:remove(item.id)
            tool = Equipment.clone(getSource(item), item)
            if not tool then return false, "Missing 3D model for " .. item.name .. "; the catalog only has its metadata/icon" end
            row.tool = tool
        end
        if state.native then
            local synced, err = state.native:sync(item, row.count, true, true)
            if not synced then self:remove(item.id); return false, err end
        end
        tool.Parent = backpack
        local equipped, err = pcall(humanoid.EquipTool, humanoid, tool)
        if not equipped or tool.Parent ~= character then
            self:remove(item.id)
            if state.native then state.native:sync(item, row.count, false, false) end
            return false, tostring(err or "Character did not equip the local Tool")
        end
        row.equipped = true
        if not self.bindings[item.id] then
            local function changed()
                if state.items[item.id] ~= row or row.tool ~= tool then return end
                row.equipped = tool.Parent == player.Character
                if state.native then
                    local ok, message = state.native:sync(item, row.count, tool.Parent ~= nil, row.equipped)
                    if not ok then notify(message) end
                end
            end
            self.bindings[item.id] = {tool.Equipped:Connect(changed), tool.Unequipped:Connect(changed)}
        end
        return true, nil, "visual"
    end
    function controller:close()
        for id in pairs(state.items) do self:remove(id) end
    end
    return controller
end

return Equipment
