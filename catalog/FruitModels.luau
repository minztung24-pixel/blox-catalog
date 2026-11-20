local Equipment = require(script.Parent.Equipment)
local FruitModels = {}

function FruitModels.new(fileExists, assetUri, getObjects)
    fileExists = fileExists or (typeof(isfile) == "function" and isfile)
    assetUri = assetUri or (typeof(getcustomasset) == "function" and getcustomasset)
    getObjects = getObjects or function(uri) return game:GetObjects(uri) end
    local root = Instance.new("Folder")
    root.Name = "BloxCatalogLocalFruitModels"
    local cache = {models = {}, native = {}, loading = {}, closed = false}
    function cache:capture(item, tool)
        if self.closed or item.category ~= "Fruits" or not tool:IsA("Tool") or not tool.Parent
            or tool:GetAttribute("BloxCatalogOwned") or tool:GetAttribute("ClientCatalogOwned")
            or tostring(tool:GetAttribute("ItemId")) ~= item.id then return nil end
        if self.native[item.id] == tool then return self.models[item.id] end
        if #tool:GetDescendants() > 3000 then return nil end
        local ok, clean = pcall(Equipment.clone,tool,item)
        if not ok or not clean then return nil end
        -- Keep a sanitized snapshot before Store/respawn removes the genuine Tool.
        clean.Parent = root
        local previous = self.models[item.id]
        self.models[item.id] = clean
        self.native[item.id] = tool
        if previous then previous:Destroy() end
        return clean
    end
    function cache:path(item)
        if self.closed or item.category ~= "Fruits" or not fileExists or not assetUri then return nil end
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
        local path = self:path(item)
        if not path then return nil,"No local model file for " .. item.name end
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
            assert(#source:GetDescendants() <= 3000,"Fruit model exceeds instance limit")
            -- Imported scripts never enter the DataModel; clone strips code, remotes and tags.
            source.Parent = root
            clean = assert(Equipment.clone(source,item),"Model has no usable BasePart")
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
            return nil,"Local model load failed: " .. tostring(message)
        end
        return self.models[item.id]
    end
    function cache:close()
        self.closed = true
        root:Destroy()
        table.clear(self.models)
        table.clear(self.native)
    end
    return cache
end

return FruitModels
