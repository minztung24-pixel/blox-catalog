local Equipment = {}

function Equipment.findExistingTool(player, item)
    local function normalized(name) return name:lower():gsub("%s", "") end
    local names = {}
    local suffix = (item.category == "Fruits" or item.isPhysicalFruit) and " Fruit" or ""
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
    local physicalFruit=item.category=="Fruits" or item.isPhysicalFruit==true
    tool.Name = item.name; tool.ToolTip = physicalFruit and "Fruits" or item.category
    tool.RequiresHandle = true; tool.CanBeDropped = false
    tool.Enabled = physicalFruit; tool.ManualActivationOnly = not physicalFruit
    tool:SetAttribute("BloxCatalogOwned", true); tool:SetAttribute("ItemId", tonumber(item.id))
    return tool
end

function Equipment.animationLoader(preload, timeout)
    preload = preload or function(objects, callback) game:GetService("ContentProvider"):PreloadAsync(objects,callback) end
    timeout = timeout or 8
    local cache = {entries={},closed=false}
    function cache:load(animator, animation)
        local id = animation.AnimationId
        assert(not self.closed,"Animation loader closed: "..id)
        local entry = self.entries[id]
        if not entry then
            entry = {};self.entries[id] = entry
            entry.asset = Instance.new("Animation");entry.asset.AnimationId = id
            entry.task = task.spawn(function()
                local finished, status, failure = false,nil,nil
                entry.request = task.spawn(function()
                    local ok, message = pcall(preload,{entry.asset},function(uri,result)
                        if uri==id or (typeof(uri)=="string" and uri:match("[?&]id=(%d+)")==id:match("%d+")) then status=result end
                    end)
                    if not ok then failure=tostring(message) end
                    finished=true
                end)
                local deadline=os.clock()+timeout
                while not finished and not self.closed and os.clock()<deadline do task.wait(.01) end
                if self.closed then return end
                if not finished then
                    pcall(task.cancel,entry.request);failure="Animation preload timed out"
                elseif not failure and status~=Enum.AssetFetchStatus.Success then
                    failure="Animation preload failed: "..tostring(status or "no fetch result")
                end
                entry.asset:Destroy()
                entry.error=failure;entry.done=true
            end)
        end
        while not entry.done and not self.closed do task.wait(.01) end
        assert(not self.closed,"Animation loader closed: "..id)
        assert(not entry.error,tostring(entry.error).." ["..id.."]")
        return animator:LoadAnimation(animation)
    end
    function cache:close()
        if self.closed then return end
        self.closed=true
        for _,entry in pairs(self.entries) do
            if entry.request then pcall(task.cancel,entry.request) end
            if entry.task then pcall(task.cancel,entry.task) end
            if entry.asset then entry.asset:Destroy() end
        end
    end
    return cache
end

function Equipment.fruitMotion(tool, notify, loadAnimation, timeout)
    assert(tool:GetAttribute("BloxCatalogOwned"),"Animate only catalog-owned clones")
    loadAnimation = loadAnimation or function(animator,animation)return animator:LoadAnimation(animation)end
    timeout = timeout or 8
    local rigs = {}
    for _,node in ipairs(tool:GetDescendants()) do
        if node:IsA("AnimationController") then
            local idle=node.Parent:FindFirstChild("Idle") or node.Parent:FindFirstChild("Animation")
            if idle and idle:IsA("Animation") and idle.AnimationId~="" then
                local animator=node:FindFirstChildOfClass("Animator") or Instance.new("Animator",node)
                table.insert(rigs,{animator=animator,animation=idle})
            end
        end
    end
    local motion={closed=false}
    local function active()return not motion.closed and motion.held and tool:IsDescendantOf(workspace)end
    local function update()
        if motion.closed then return end
        local status=motion.held and "Ready" or "Stopped"
        if #rigs==0 then status="Missing" end
        for _,rig in ipairs(rigs) do
            if rig.error then
                tool:SetAttribute("BloxCatalogAnimationStatus","Failed")
                tool:SetAttribute("BloxCatalogAnimationError",rig.error)
                return "Failed"
            elseif motion.held and not rig.ready then status="Loading" end
        end
        tool:SetAttribute("BloxCatalogAnimationStatus",status)
        tool:SetAttribute("BloxCatalogAnimationError",nil)
        return status
    end
    function motion:setActive(held)
        if self.closed or self.held==held then return end
        if held and not tool:IsDescendantOf(workspace) then return end
        self.held=held
        if not held then
            for _,rig in ipairs(rigs) do if rig.track then pcall(rig.track.Stop,rig.track,0.1) end end
            update();return
        end
        for _,rig in ipairs(rigs) do rig.ready=false end
        update()
        if #rigs==0 then notify("Model contains no idle animation: "..tool.Name);return end
        for _,rig in ipairs(rigs) do
            if rig.error then notify(rig.error)
            elseif not rig.busy then
                rig.busy=true
                rig.worker=task.defer(function()
                    local ok,message=pcall(function()
                        if not rig.track then
                            local track=assert(loadAnimation(rig.animator,rig.animation),"No animation track returned")
                            if self.closed then track:Destroy();return end
                            rig.track=track
                        end
                        local deadline=os.clock()+timeout
                        while active() and rig.track.Length<=0 and os.clock()<deadline do task.wait(.01) end
                        if not active() then return end
                        assert(rig.track.Length>0,"Animation track has no loaded data after timeout")
                        rig.track.Looped=true
                        rig.track.Priority=Enum.AnimationPriority.Idle
                        rig.track:Play(0.1)
                        rig.ready=true
                    end)
                    rig.busy=false
                    if self.closed then return end
                    if not ok then
                        rig.error="Fruit animation unavailable: "..tool.Name.." ["..rig.animation.AnimationId.."]: "..tostring(message)
                        if rig.track then
                            pcall(rig.track.Stop,rig.track,0.1);pcall(rig.track.Destroy,rig.track);rig.track=nil
                        end
                        warn("[Blox Catalog] "..rig.error)
                        if active() then notify(rig.error) end
                    end
                    if update()=="Ready" and active() then notify("Fruit animation ready: "..tool.Name) end
                end)
            end
        end
    end
    function motion:close()
        if self.closed then return end
        self.closed=true
        for _,rig in ipairs(rigs) do
            if rig.worker then pcall(task.cancel,rig.worker) end
            if rig.track then pcall(rig.track.Stop,rig.track,0.1);pcall(rig.track.Destroy,rig.track) end
        end
        table.clear(rigs)
    end
    return motion
end

local function dropCollider(tool,handle)
    local low=Vector3.new(math.huge,math.huge,math.huge)
    local high=Vector3.new(-math.huge,-math.huge,-math.huge)
    local collider=tool:FindFirstChild("BloxCatalogDropCollider")
    for _,part in ipairs(tool:GetDescendants()) do
        if part:IsA("BasePart") and part~=handle and part~=collider and part.Transparency<1 then
            local relative=handle.CFrame:ToObjectSpace(part.CFrame)
            local half=part.Size*.5
            for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
                local point=relative:PointToWorldSpace(Vector3.new(half.X*x,half.Y*y,half.Z*z))
                low=low:Min(point);high=high:Max(point)
            end end end
        end
    end
    if low.X==math.huge then return handle end
    if not collider then
        collider=Instance.new("Part")
        collider.Name="BloxCatalogDropCollider"
        collider.Transparency=1;collider.CanCollide=false;collider.CanTouch=false;collider.CanQuery=false;collider.Massless=true
        collider.Parent=tool
    end
    local previous=collider:FindFirstChildOfClass("WeldConstraint")
    if previous then previous:Destroy() end
    collider.Size=(high-low):Max(Vector3.new(.05,.05,.05))
    collider.CFrame=handle.CFrame*CFrame.new((low+high)*.5)
    local weld=Instance.new("WeldConstraint")
    weld.Part0=handle;weld.Part1=collider;weld.Parent=collider
    return collider
end

function Equipment.new(state, player, getSource, notify, onFruitActivated)
    local controller = {bindings = {}, animations = {}, dropBindings = {}}
    local animationLoader = Equipment.animationLoader()
    function controller:remove(id)
        if self.dropBindings[id] then self.dropBindings[id]:Disconnect(); self.dropBindings[id] = nil end
        if self.animations[id] then self.animations[id]:close(); self.animations[id] = nil end
        for _, connection in ipairs(self.bindings[id] or {}) do connection:Disconnect() end
        self.bindings[id] = nil
        local row = state.items[id]
        if row and row.tool then
            if row.tool:GetAttribute("BloxCatalogOwned") then row.tool:Destroy() end
            row.tool = nil
            row.equipped = false
        end
    end
    function controller:store(item)
        local row=state.items[item.id]
        if not row or not row.tool or not row.tool:GetAttribute("BloxCatalogOwned") then return false,"Only local fruit visuals can be stored here" end
        if state.native then
            local ok,message=state.native:sync(item,row.count,false,false)
            if not ok then return false,message end
        end
        self:remove(item.id)
        return true
    end
    function controller:drop(item)
        local row=state.items[item.id]
        local tool=row and row.tool
        local character=player.Character
        local root=character and character:FindFirstChild("HumanoidRootPart")
        local handle=tool and tool:FindFirstChild("Handle")
        if not tool or not tool:GetAttribute("BloxCatalogOwned") or tool.Parent~=character
            or not root or not handle or not handle:IsA("BasePart") then return false,"Hold the local fruit first" end
        -- Release only this Tool's external grip before moving its assembly.
        for _,joint in ipairs(handle:GetJoints()) do
            if joint:IsA("JointInstance") and (joint.Part0==handle or joint.Part1==handle)
                and (not joint.Part0 or not joint.Part0:IsDescendantOf(tool)
                    or not joint.Part1 or not joint.Part1:IsDescendantOf(tool)) then
                joint:Destroy()
            end
        end
        handle.CanTouch=false
        local collider=dropCollider(tool,handle)
        tool.Parent=workspace
        handle.CFrame=root.CFrame*CFrame.new(0,0,-5)
        handle.CanCollide=collider==handle
        collider.CanCollide=true
        handle.Massless=false
        handle.AssemblyLinearVelocity=Vector3.new(0,1,0)
        handle.AssemblyAngularVelocity=Vector3.zero
        row.equipped=false
        local prompt=handle:FindFirstChild("BloxCatalogPickup")
        if prompt then prompt:Destroy() end
        if self.dropBindings[item.id] then self.dropBindings[item.id]:Disconnect() end
        local readyAt=os.clock()+.5
        self.dropBindings[item.id]=handle.Touched:Connect(function(hit)
            local currentCharacter=player.Character
            if os.clock()<readyAt or tool.Parent~=workspace or state.items[item.id]~=row or row.tool~=tool
                or not currentCharacter or not hit:IsDescendantOf(currentCharacter) then return end
            local ok,message=self:equip(item)
            if not ok then notify(tostring(message)) end
        end)
        handle.CanTouch=true
        return true
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
            local source, sourceError = getSource(item)
            tool = Equipment.clone(source, item)
            if not tool then return false, sourceError or ("Missing 3D model for " .. item.name .. "; the catalog only has its metadata/icon") end
            row.tool = tool
        end
        if state.native then
            local synced, err = state.native:sync(item, row.count, true, true)
            if not synced then self:remove(item.id); return false, err end
        end
        tool.Parent = backpack
        tool.Handle.CanCollide=false
        tool.Handle.CanTouch=false
        tool.Handle.Massless=true
        local collider=tool:FindFirstChild("BloxCatalogDropCollider")
        if collider then collider.CanCollide=false end
        local pickup=tool.Handle:FindFirstChild("BloxCatalogPickup")
        if pickup then pickup.Enabled=false end
        local equipped, err = pcall(humanoid.EquipTool, humanoid, tool)
        if not equipped or tool.Parent ~= character then
            self:remove(item.id)
            if state.native then state.native:sync(item, row.count, false, false) end
            return false, tostring(err or "Character did not equip the local Tool")
        end
        row.equipped = true
        if (item.category == "Fruits" or item.isPhysicalFruit) and not self.animations[item.id] then
            self.animations[item.id] = Equipment.fruitMotion(tool,notify,function(animator,animation)
                return animationLoader:load(animator,animation)
            end)
        end
        local motion = self.animations[item.id]
        if motion then motion:setActive(true) end
        if not self.bindings[item.id] then
            local function changed()
                if state.items[item.id] ~= row or row.tool ~= tool then return end
                row.equipped = tool.Parent == player.Character
                if motion then motion:setActive(tool:IsDescendantOf(workspace)) end
                if state.native then
                    local ok, message = state.native:sync(item, row.count, tool.Parent ~= nil, row.equipped)
                    if not ok then notify(message) end
                end
            end
            self.bindings[item.id] = {tool.Equipped:Connect(changed), tool.Unequipped:Connect(changed), tool.AncestryChanged:Connect(changed),
                tool.Destroying:Connect(function() if motion then motion:close() end end)}
            if (item.category=="Fruits" or item.isPhysicalFruit) and onFruitActivated then
                table.insert(self.bindings[item.id],tool.Activated:Connect(function()
                    if tool.Parent==player.Character then onFruitActivated(item,tool) end
                end))
            end
        end
        return true, nil, "visual"
    end
    function controller:close(final)
        for id in pairs(state.items) do self:remove(id) end
        if final then animationLoader:close() end
    end
    return controller
end

return Equipment
