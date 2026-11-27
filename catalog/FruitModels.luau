local Equipment = require(script.Parent.Equipment)
local FruitAnimations = require(script.Parent.FruitAnimations)
local FruitModels = {}

function FruitModels.new(fileExists, assetUri, getObjects)
    fileExists = fileExists or (typeof(isfile) == "function" and isfile)
    assetUri = assetUri or (typeof(getcustomasset) == "function" and getcustomasset)
    getObjects = getObjects or function(uri) return game:GetObjects(uri) end
    local root = Instance.new("Folder")
    root.Name = "BloxCatalogLocalFruitModels"
    local cache = {models = {}, native = {}, foreign = {}, archived = {}, loading = {}, errors = {}, closed = false}
    local stopWatching
    function cache:capture(item, tool, refresh, foreign)
        if self.closed then return nil end
        local holder=tool.Parent
        local preview=holder and holder.Name=="__ReplicatedSpinnerInstances" and holder.Parent and holder.Parent:IsA("PlayerGui")
        if not (item.category=="Fruits" or item.isPhysicalFruit) or not (tool:IsA("Tool") or preview and tool:IsA("Model")) or not holder
            or tool:GetAttribute("BloxCatalogOwned") or tool:GetAttribute("ClientCatalogOwned")
            or tostring(tool:GetAttribute("ItemId")) ~= item.id then return nil end
        -- Prefer a captured held Tool over transient preview copies of the same item.
        if preview and self.native[item.id] and self.native[item.id]~=tool then return self.models[item.id] end
        if self.native[item.id] == tool and not refresh then return self.models[item.id] end
        if #tool:GetDescendants() > 3000 then return nil end
        local ok, clean = pcall(Equipment.clone,tool,item)
        if not ok or not clean then return nil end
        -- Keep a sanitized snapshot before Store/respawn or the native preview removes its source.
        clean.Parent = root
        local previous = self.models[item.id]
        self.models[item.id] = clean
        self.errors[item.id] = nil
        self.native[item.id] = tool
        self.foreign[item.id] = foreign or nil
        self.archived[item.id] = nil
        if previous then previous:Destroy() end
        if self.archive then self.archive:enqueue(item,clean) end
        return clean
    end
    function cache:watch(player,items,onChange)
        assert(not self.closed and not stopWatching,"Fruit source watcher already started or closed")
        local watched,pending,connections={}, {}, {}
        local players=game:GetService("Players")
        local peers={}
        local watchedCount,notifyPending,stopped=0,false,false
        local function sourceFor(node)
            while node and node~=workspace and node~=player do
                local parent=node.Parent
                if parent and (parent==workspace or parent==player.Character
                    or parent:IsA("Backpack") and parent.Parent==player
                    or parent:IsA("Model") and players:GetPlayerFromCharacter(parent))then
                    return node:IsA("Tool") and node or nil
                elseif parent and parent.Parent and parent.Name=="__ReplicatedSpinnerInstances" and parent.Parent==player:FindFirstChildOfClass("PlayerGui")then
                    return (node:IsA("Tool")or node:IsA("Model"))and node or nil
                end
                node=parent
            end
        end
        local function unwatch(source)
            local bindings=watched[source]
            if not bindings then return end
            watched[source]=nil;watchedCount-=1
            for _,connection in ipairs(bindings)do connection:Disconnect()end
        end
        local function queue(source)
            if stopped or self.closed or pending[source]then return end
            pending[source]=true
            task.defer(function()
                pending[source]=nil
                if stopped or self.closed or sourceFor(source)~=source then return end
                local item=items[tostring(source:GetAttribute("ItemId")or "")]
                if not item or not (item.category=="Fruits"or item.isPhysicalFruit)then return end
                local parent=source.Parent
                local foreign=parent and parent~=player.Character and parent:IsA("Model") and players:GetPlayerFromCharacter(parent)~=nil
                if foreign and self.native[item.id] and not self.foreign[item.id]and self.native[item.id]~=source then return end
                local previous=self.models[item.id]
                local captured=self:capture(item,source,true,foreign)
                if captured and captured~=previous and onChange and not notifyPending then
                    notifyPending=true
                    task.defer(function()
                        notifyPending=false
                        if not stopped and not self.closed then onChange()end
                    end)
                end
            end)
        end
        local function added(node)
            local source=sourceFor(node)
            if not source or source:GetAttribute("BloxCatalogOwned")or source:GetAttribute("ClientCatalogOwned")then return end
            if not watched[source]then
                local id=source:GetAttribute("ItemId")
                local item=id and items[tostring(id)]
                if id and (not item or not (item.category=="Fruits"or item.isPhysicalFruit))then return end
                if watchedCount>=256 then return end
                watchedCount+=1
                watched[source]={
                    source:GetAttributeChangedSignal("ItemId"):Connect(function()queue(source)end),
                    source.AncestryChanged:Connect(function()
                        if sourceFor(source)==source then queue(source)else unwatch(source)end
                    end),
                    source.Destroying:Connect(function()unwatch(source)end),
                }
            end
            queue(source)
        end
        stopWatching=function()
            stopped=true
            for _,connection in ipairs(connections)do connection:Disconnect()end
            for source in pairs(watched)do unwatch(source)end
            for _,connection in pairs(peers)do connection:Disconnect()end
            table.clear(peers)
            table.clear(pending)
        end
        table.insert(connections,player.DescendantAdded:Connect(added))
        table.insert(connections,workspace.DescendantAdded:Connect(added))
        local function peerAdded(peer)
            if peer==player or peers[peer]then return end
            local function characterAdded(character)
                for _,node in ipairs(character:GetChildren())do added(node)end
            end
            peers[peer]=peer.CharacterAdded:Connect(characterAdded)
            if peer.Character then characterAdded(peer.Character)end
        end
        table.insert(connections,players.PlayerAdded:Connect(peerAdded))
        table.insert(connections,players.PlayerRemoving:Connect(function(peer)
            if peers[peer]then peers[peer]:Disconnect();peers[peer]=nil end
        end))
        for _,peer in ipairs(players:GetPlayers())do peerAdded(peer)end
        local gui=player:FindFirstChildOfClass("PlayerGui")
        for _,container in pairs({player:FindFirstChildOfClass("Backpack"),player.Character,
            gui and gui:FindFirstChild("__ReplicatedSpinnerInstances"),workspace})do
            for _,node in ipairs(container:GetChildren())do added(node)end
        end
    end
    function cache:path(item)
        if self.closed or not (item.category=="Fruits" or item.isPhysicalFruit) or not fileExists or not assetUri then return nil end
        for _, name in ipairs({item.storageKey, item.name}) do
            if name and name ~= "" and not name:find("[/\\:]") and not name:find("..",1,true) then
                local path = "codex_fruit_studio/models/" .. name .. ".rbxm"
                local ok, exists = pcall(fileExists,path)
                if ok and exists then return path end
            end
        end
        return nil
    end
    function cache:load(item)
        if self.closed then return nil,"Fruit model cache is closed" end
        if self.models[item.id] then return self.models[item.id] end
        if self.loading[item.id] then return nil,"Fruit model is loading; try again" end
        local archiveError
        if self.archive then
            self.loading[item.id]=true
            local restored,message=self.archive:load(item)
            self.loading[item.id]=nil
            if restored then
                if self.closed or self.models[item.id]then restored:Destroy()
                else restored.Parent=root;self.models[item.id]=restored;self.archived[item.id]=true end
                return self.models[item.id]
            end
            archiveError=message
        end
        local path = self:path(item)
        if not path then return nil,archiveError or ("No local model file for " .. item.name) end
        self.loading[item.id] = true
        local objects, clean
        local ok, message = pcall(function()
            objects = getObjects(assetUri(path))
            if self.native[item.id] then return end
            assert(typeof(objects) == "table" and #objects > 0 and #objects <= 20,"Invalid model file contents")
            local source
            for _, object in ipairs(objects) do
                assert(typeof(object) == "Instance","Invalid model object")
                if object:IsA("Tool") or object:IsA("Model") then
                    assert(not source,"Model file contains multiple roots")
                    source = object
                end
            end
            assert(source,"Model file has no Tool or Model")
            local id = source:GetAttribute("ItemId")
            assert(id == nil or tostring(id) == item.id,"Model ItemId does not match catalog")
            -- This mislabeled export contains the Galaxy skin, not the base Empyrean model.
            assert(not (item.id=="1041" and id==nil and source.Name=="Galaxy Empyrean Kitsune Fruit"),
                "Wrong Empyrean model: this local export contains Galaxy; a genuine Empyrean model is required")
            assert(#source:GetDescendants() <= 3000,"Fruit model exceeds instance limit")
            -- Imported scripts never enter the DataModel; clone strips code, remotes and tags.
            source.Parent = root
            clean = assert(Equipment.clone(source,item),"Model has no usable BasePart")
            FruitAnimations.apply(clean,item)
            local fruit = clean:FindFirstChild("Fruit")
            local idle = fruit and fruit:FindFirstChild("Idle")
            -- Native Buddha capture and typed preload verified this exact export correction.
            if item.id == "1393" and idle and idle:IsA("Animation") and idle.AnimationId == "rbxassetid://78877647242196" then
                idle.AnimationId = "rbxassetid://15123606541"
            end
            assert(not self.closed,"Fruit model cache was closed while loading")
            clean.Parent = root
            self.models[item.id] = clean
        end)
        if typeof(objects) == "table" then
            for _, object in ipairs(objects) do if typeof(object) == "Instance" then object:Destroy() end end
        end
        self.loading[item.id] = nil
        if not ok then
            if clean then clean:Destroy() end
            local reason="Local model load failed: " .. tostring(message)
            self.errors[item.id]={path=path,message=reason}
            return nil,reason
        end
        self.errors[item.id]=nil
        return self.models[item.id]
    end
    function cache:available(item)
        if self.closed then return false end
        local model=self.models[item.id]
        if model and model.Parent then return true end
        if self.archive and self.archive:available(item)then return true end
        local path=self:path(item)
        local failure=self.errors[item.id]
        return path~=nil and (not failure or failure.path~=path)
    end
    function cache:clearErrors()
        table.clear(self.errors)
        if self.archive then self.archive:clearErrors()end
    end
    function cache:close()
        self.closed = true
        if stopWatching then stopWatching();stopWatching=nil end
        if self.archive then self.archive:close()end
        root:Destroy()
        table.clear(self.models)
        table.clear(self.native)
        table.clear(self.foreign)
        table.clear(self.archived)
        table.clear(self.errors)
    end
    return cache
end

return FruitModels
