--!strict
-- Run in Roblox Studio with a model and animation you have permission to use.
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")

return function(source: Model | Tool, candidate: Animation?)
    assert(RunService:IsStudio(), "Studio only")
    assert(source:IsA("Model") or source:IsA("Tool"), "Expected a Model or Tool")

    local handle = source:FindFirstChild("Handle")
    local result = {
        model = source.Name,
        itemId = tostring(source:GetAttribute("ItemId") or ""),
        canAttachByHandle = source:IsA("Tool") and handle ~= nil and handle:IsA("BasePart"),
        meshes = 0,
        vfx = 0,
        enabledVfx = 0,
        joints = 0,
        movingJoints = 0,
        clip = "",
        status = "",
        detail = "",
    }
    local rig: Humanoid | AnimationController? = nil
    local multipleRigs = false
    for _, node in source:GetDescendants() do
        if node:IsA("MeshPart") then
            result.meshes += 1
        elseif node:IsA("Bone") or node:IsA("Motor6D") or node:IsA("AnimationConstraint") then
            result.joints += 1
        elseif node:IsA("ParticleEmitter") or node:IsA("Trail") or node:IsA("Beam") then
            result.vfx += 1
            if node.Enabled then
                result.enabledVfx += 1
            end
        elseif node:IsA("AnimationController") or node:IsA("Humanoid") then
            multipleRigs = rig ~= nil
            rig = node
        end
    end
    local clip = candidate or (rig and rig.Parent and
        (rig.Parent:FindFirstChild("Idle") or rig.Parent:FindFirstChild("Animation")))
    if not clip or not clip:IsA("Animation") or clip.AnimationId == "" then
        result.status = "MissingClip"
        return result
    end

    result.clip = clip.AnimationId
    local assetId = result.clip:match("^rbxassetid://(%d+)$")
    if not assetId then
        result.status = "InvalidClipId"
        return result
    end
    if not rig or result.joints == 0 or multipleRigs then
        result.status = if multipleRigs then "MultipleRigs" else "MissingRig"
        return result
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = result.clip
    local finished = false
    local fetchStatus: Enum.AssetFetchStatus? = nil
    local worker = task.spawn(function()
        local ok, err = pcall(function()
            ContentProvider:PreloadAsync({animation}, function(uri, status)
                if uri == result.clip or uri:match("[?&]id=(%d+)") == assetId then
                    fetchStatus = status
                end
            end)
        end)
        if not ok then result.detail = tostring(err) end
        finished = true
    end)
    local deadline = os.clock() + 8
    while not finished and os.clock() < deadline do
        task.wait(.05)
    end
    if not finished or fetchStatus ~= Enum.AssetFetchStatus.Success then
        if not finished then pcall(task.cancel, worker) end
        animation:Destroy()
        result.status = if finished then "LoadFailed" else "PreloadTimeout"
        if result.detail == "" and fetchStatus then result.detail = tostring(fetchStatus) end
        return result
    end
    if not RunService:IsRunning() then
        animation:Destroy()
        result.status = "LoadedNeedsPlay"
        return result
    end

    local clone: Instance?
    local track: AnimationTrack?
    local ok, err = pcall(function()
        local copy = assert(source:Clone(), "Source model cannot be cloned")
        clone = copy
        copy.Name = "StudioAssetMotionCheck"
        for _, tag in copy:GetTags() do copy:RemoveTag(tag) end
        local controller = copy:FindFirstChildWhichIsA("AnimationController", true) or
            copy:FindFirstChildWhichIsA("Humanoid", true)
        assert(controller and (controller:IsA("AnimationController") or controller:IsA("Humanoid")), "Controller missing on clone")
        local animator = controller:FindFirstChildOfClass("Animator") or Instance.new("Animator", controller)
        local joints: {Bone | Motor6D | AnimationConstraint} = {}
        for _, node in copy:GetDescendants() do
            for _, tag in node:GetTags() do node:RemoveTag(tag) end
            if node:IsA("LuaSourceContainer") or node:IsA("Sound") or node:IsA("ProximityPrompt") or node:IsA("ClickDetector") then
                node:Destroy()
            elseif node:IsA("BasePart") then
                node.Anchored = true
                node.CanCollide = false
                node.CanTouch = false
                node.CanQuery = false
                node.Transparency = 1
            elseif node:IsA("Bone") or node:IsA("Motor6D") or node:IsA("AnimationConstraint") then
                if node:IsA("Motor6D") then
                    assert(node.Part0 and node.Part0:IsDescendantOf(copy) and node.Part1 and node.Part1:IsDescendantOf(copy),
                        "Motor6D must connect two parts of the checked rig")
                elseif node:IsA("AnimationConstraint") then
                    assert(node.Attachment0 and node.Attachment0:IsDescendantOf(copy)
                        and node.Attachment1 and node.Attachment1:IsDescendantOf(copy),
                        "AnimationConstraint must connect attachments of the checked rig")
                end
                table.insert(joints, node)
            elseif node:IsA("JointInstance") or node:IsA("WeldConstraint") or node:IsA("NoCollisionConstraint") then
                if not node.Part0 or not node.Part0:IsDescendantOf(copy) or not node.Part1 or not node.Part1:IsDescendantOf(copy) then
                    node:Destroy()
                end
            elseif node:IsA("Constraint") then
                if (node.Attachment0 and not node.Attachment0:IsDescendantOf(copy))
                    or (node.Attachment1 and not node.Attachment1:IsDescendantOf(copy)) then
                    node:Destroy()
                end
            elseif node:IsA("ParticleEmitter") or node:IsA("Trail") or node:IsA("Beam") or node:IsA("Light") then
                node.Enabled = false
            end
        end
        assert(#joints == result.joints, "Joints missing on clone")
        copy.Parent = workspace
        local playing = animator:LoadAnimation(animation)
        track = playing
        local trackDeadline = os.clock() + 6
        while playing.Length <= 0 and os.clock() < trackDeadline do
            task.wait(.05)
        end
        if playing.Length <= 0 then
            result.status = "TrackTimeout"
            return
        end
        playing.Priority = Enum.AnimationPriority.Action
        playing:Play(0, 1, 0)
        local previous: {[Instance]: CFrame} = {}
        local moved: {[Instance]: boolean} = {}
        for phase = 0, 7 do
            playing.TimePosition = playing.Length * phase / 8
            RunService.Heartbeat:Wait()
            RunService.Heartbeat:Wait()
            for _, joint in joints do
                local pose = joint.Transform
                local before = previous[joint]
                if before and not moved[joint] and not before:FuzzyEq(pose, 0.0001) then
                    moved[joint] = true
                    result.movingJoints += 1
                end
                previous[joint] = pose
            end
        end
        result.status = if result.movingJoints > 0 then "Moved" else "NoMotionObserved"
    end)
    if track then track:Destroy() end
    if clone then clone:Destroy() end
    animation:Destroy()
    if not ok then
        result.status = "PlaybackError"
        result.detail = tostring(err)
    end
    return result
end
