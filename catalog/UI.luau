local Catalog = require(script.Parent.Catalog)
local Inventory = require(script.Parent.Inventory)
local NativeItems = require(script.Parent.NativeItems)
local NativeEquip = require(script.Parent.NativeEquip)
local NativeDialogue = require(script.Parent.NativeDialogue)
local Equipment = require(script.Parent.Equipment)
local FruitModels = require(script.Parent.FruitModels)
local UI = {}

function UI.start()
    local Players = game:GetService("Players")
    local Input = game:GetService("UserInputService")
    local player = assert(Players.LocalPlayer, "Run the catalog on the client")
    local playerGui = player:WaitForChild("PlayerGui")
    local previous = playerGui:FindFirstChild("BloxCatalogSim")
    if previous then previous:Destroy() end
    local colors = {
        background = Color3.fromRGB(15, 17, 23), surface = Color3.fromRGB(34, 37, 49),
        edge = Color3.fromRGB(44, 151, 204), text = Color3.fromRGB(241, 244, 250),
        muted = Color3.fromRGB(169, 181, 197), green = Color3.fromRGB(9, 123, 82),
        available = Color3.fromRGB(25, 54, 43), red = Color3.fromRGB(175, 52, 71),
    }
    local accents = {Fruits = Color3.fromRGB(190, 55, 78), Permanent = Color3.fromRGB(48, 135, 220),
        ["Fruit Skins"] = Color3.fromRGB(175, 58, 162), Premium = Color3.fromRGB(121, 78, 180),
        Swords = Color3.fromRGB(193, 133, 38), Guns = Color3.fromRGB(65, 125, 171), Skills = Color3.fromRGB(52, 142, 126)}
    local state = Inventory.new()
    local tab, category, query, page = "Inventory", "Fruits", "", 1
    local flags = {Visual = true, Balance = true, ["Gift Perm"] = true, Icons = true, Preview3D = true}
    local models, connections, modal, render, refreshModels, updateQuantity = {}, {}, nil, nil, nil, nil
    local fruitModels = FruitModels.new()
    local alive, scanning = true, false
    local showFruitMenu
    local nativeDialogue

    local function make(class, parent, props)
        local object = Instance.new(class)
        for key, value in pairs(props or {}) do object[key] = value end
        object.Parent = parent
        return object
    end
    local function round(object, border)
        make("UICorner", object, {CornerRadius = UDim.new(0, 8)})
        if border then make("UIStroke", object, {Color = colors.edge, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}) end
    end
    local function text(parent, name, value, position, size, fontSize, muted)
        return make("TextLabel", parent, {Name = name, Text = value, Position = position, Size = size,
            BackgroundTransparency = 1, TextColor3 = muted and colors.muted or colors.text,
            Font = Enum.Font.GothamMedium, TextSize = fontSize or 12, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left, RichText = false})
    end
    local function button(parent, name, value, position, size, callback, color)
        local object = make("TextButton", parent, {Name = name, Text = value, Position = position, Size = size,
            BackgroundColor3 = color or colors.surface, TextColor3 = colors.text, TextSize = 12,
            Font = Enum.Font.GothamMedium, BorderSizePixel = 0, Selectable = true})
        round(object, true)
        object.Activated:Connect(callback)
        return object
    end
    local function box(parent, name, placeholder, position, size)
        local object = make("TextBox", parent, {Name = name, Text = "", PlaceholderText = placeholder,
            Position = position, Size = size, BackgroundColor3 = colors.surface, BorderSizePixel = 0,
            TextColor3 = colors.text, PlaceholderColor3 = colors.muted, Font = Enum.Font.Gotham,
            TextSize = 13, ClearTextOnFocus = false})
        round(object, true)
        make("UIPadding", object, {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})
        return object
    end
    local gui = make("ScreenGui", playerGui, {Name = "BloxCatalogSim", ResetOnSpawn = false,
        DisplayOrder = 85, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets})
    gui:SetAttribute("Simulation", true)
    local panel = make("Frame", gui, {Name = "Panel", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = colors.background,
        BorderSizePixel = 0, ClipsDescendants = true, Active = true})
    round(panel, true)
    text(panel, "Title", "BLOX CATALOG v12.1", UDim2.fromOffset(14, 6), UDim2.new(1, -220, 0, 32), 18)
    gui:SetAttribute("Version", 12.1)
    local drag = make("TextButton", panel, {Name = "DragTitle", BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1, -202, 0, 42), Selectable = false})
    local openButton
    button(panel, "Hide", "Hide", UDim2.new(1, -122, 0, 4), UDim2.fromOffset(60, 38), function()
        panel.Visible = false; openButton.Visible = true
    end)
    button(panel, "Close", "X", UDim2.new(1, -54, 0, 4), UDim2.fromOffset(44, 38), function() gui:Destroy() end, colors.red)
    openButton = button(gui, "Reopen", "Catalog", UDim2.fromOffset(12, 60), UDim2.fromOffset(100, 44), function()
        panel.Visible = true; openButton.Visible = false
    end)
    openButton.Visible = false
    local nav = make("Frame", panel, {Name = "Navigation", BackgroundTransparency = 1})
    local info = text(panel, "SnapshotInfo", Catalog.count .. " records / local simulation", UDim2.new(), UDim2.new(), 11, true)
    local search = box(panel, "Search", "Search name / ID / rarity", UDim2.new(), UDim2.new())
    local tabs = make("Frame", panel, {Name = "Categories", BackgroundTransparency = 1})
    local content = make("ScrollingFrame", panel, {Name = "Items", BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 5, ScrollBarImageColor3 = colors.edge, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y})
    local footer = make("Frame", panel, {Name = "Footer", BackgroundTransparency = 1})
    local status = text(panel, "Status", "Simulation / Right Shift: show or hide", UDim2.new(), UDim2.new(), 11, true)
    local function tell(value) if alive then status.Text = value end end
    local function sourceFor(item)
        return (fruitModels.native[item.id] and fruitModels.models[item.id]) or models[item.id]
            or (item.physicalId and models[tostring(item.physicalId)]) or fruitModels.models[item.id]
    end
    local equipment = Equipment.new(state, player, function(item)
        local source = sourceFor(item)
        if source then return source end
        if item.category == "Fruits" then return fruitModels:load(item) end
    end, tell, function(item,tool) if showFruitMenu then showFruitMenu(item,tool) end end)
    state.removeEquipment = function(id) equipment:remove(id) end
    local function equip(item)
        local ok, err, mode = equipment:equip(item)
        local prefix=mode=="existing" and "Equipped existing Tool: "
            or (item.category=="Fruits" and "Fruit equipped / checking animation: " or "Equipped local visual: ")
        local row=state.items[item.id]
        local animationError
        if ok and mode=="visual" and row and row.tool then
            local animationStatus=row.tool:GetAttribute("BloxCatalogAnimationStatus")
            if animationStatus=="Missing" then prefix="Fruit equipped / model has no idle animation: "
            elseif animationStatus=="Ready" then prefix="Fruit animation ready: "
            elseif animationStatus=="Failed" then animationError=row.tool:GetAttribute("BloxCatalogAnimationError") end
        end
        tell(animationError or (ok and (prefix..item.name) or ("Equip unavailable: "..tostring(err))))
        if not ok then warn("[Blox Catalog] Equip unavailable: " .. tostring(err)) end
        return ok, err, mode
    end
    local nativeEquip=NativeEquip.new(playerGui,state,equip)
    task.spawn(function()
        while alive do nativeEquip:refresh();task.wait(0.2) end
    end)
    local function useVisual(item)
        if not Equipment.findExistingTool(player, item) and not state.items[item.id] then
            if not sourceFor(item) then
                tell("Missing 3D model for " .. item.name .. ". View shows its icon; no Tool is available to equip.")
                return
            end
            local ok, err = Inventory.add(state, item)
            if not ok then tell("Add failed: " .. tostring(err)); return end
            updateQuantity()
        end
        local ok, _, mode = equip(item)
        if ok then
            state.visualId = item.id
            if state.items[item.id] then state.items[item.id].visual = mode == "visual" end
            gui:SetAttribute("VisualItemId", item.id)
        end
    end
    local function closeModal()
        if nativeDialogue then nativeDialogue:dismiss() end
        local current=modal;modal=nil
        if current then current:Destroy() end
    end
    local function openModal(title)
        closeModal()
        modal = make("Frame", gui, {Name = "Modal", Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.25, ZIndex = 20, Active = true})
        local body = make("Frame", modal, {Name = "Body", AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -40, 1, -40),
            BackgroundColor3 = colors.background, ZIndex = 21, BorderSizePixel = 0})
        make("UISizeConstraint", body, {MaxSize = Vector2.new(480, 500)})
        round(body, true)
        text(body, "Title", title, UDim2.fromOffset(16, 8), UDim2.new(1, -84, 0, 40), 15)
        button(body, "CloseModal", "X", UDim2.new(1, -56, 0, 8), UDim2.fromOffset(40, 40), closeModal)
        local scroll = make("ScrollingFrame", body, {Name = "Contents", Position = UDim2.fromOffset(12, 60),
            Size = UDim2.new(1, -24, 1, -72), BackgroundTransparency = 1, BorderSizePixel = 0,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4})
        return scroll
    end
    showFruitMenu = function(item,tool)
        if nativeDialogue and nativeDialogue.running then return end
        closeModal()
        local function menuError(reason)
            local message="Fruit menu unavailable: "..tostring(reason)
            tell(message);warn("[Blox Catalog] "..message)
            if typeof(writefile)=="function" then pcall(writefile,"blox-catalog-menu-error.txt",message) end
        end
        if not nativeDialogue then
            local connected,value=pcall(NativeDialogue.connect)
            if not connected then menuError(value);return end
            nativeDialogue=value
        end
        if not alive then nativeDialogue:close();return end
        tell("Local visual menu / Drop and Store affect this client only.")
        local wasEnabled=gui.Enabled
        gui.Enabled=false
        local called,ok,message=pcall(nativeDialogue.show,nativeDialogue,tool,{
            Eat=function()tell("Eating requires a real server-owned fruit; this visual grants no abilities.")end,
            Drop=function()
                local success,err=equipment:drop(item)
                tell(success and "Dropped local visual. Use its pickup prompt to hold it again." or tostring(err))
            end,
            Store=function()
                local success,err=equipment:store(item)
                if success then updateQuantity();render() end
                tell(success and "Local fruit returned to stock." or tostring(err))
            end,
        })
        if alive then
            gui.Enabled=wasEnabled
            if not called or not ok then menuError(called and message or ok) end
        end
    end
    local function image(parent, item, position, size)
        local label = make("ImageLabel", parent, {Name = "Icon", Image = item.icon, BackgroundTransparency = 1,
            Position = position, Size = size, ScaleType = Enum.ScaleType.Fit})
        if item.iconRectOffset then label.ImageRectOffset = Vector2.new(table.unpack(item.iconRectOffset)) end
        if item.iconRectSize then label.ImageRectSize = Vector2.new(table.unpack(item.iconRectSize)) end
        if item.icon == "" then
            text(parent, "MissingIcon", "?", position, size, 28, true)
        end
        return label
    end
    local function modelPreview(parent, item)
        local source = sourceFor(item)
        if not source or not source.Parent then return false end
        local ok, clone = pcall(function() return source:Clone() end)
        if not ok or not clone then return false end
        for _, node in ipairs(clone:GetDescendants()) do
            if node:IsA("LuaSourceContainer") or node:IsA("Sound") then node:Destroy()
            elseif node:IsA("BasePart") then node.Anchored = true; node.CanCollide = false end
        end
        if not clone:FindFirstChildWhichIsA("BasePart", true) then clone:Destroy(); return false end
        local viewport = make("ViewportFrame", parent, {Name = "ModelPreview", BackgroundTransparency = 1,
            Position = UDim2.fromOffset(0, 0), Size = UDim2.new(1, 0, 0, 180), Ambient = Color3.fromRGB(200, 200, 200)})
        local world = make("WorldModel", viewport)
        local model = make("Model", world)
        clone.Parent = model
        local center, size = model:GetBoundingBox()
        local camera = make("Camera", viewport, {FieldOfView = 40})
        camera.CFrame = CFrame.lookAt(center.Position + Vector3.new(1, 0.6, 1.6).Unit * math.max(2, size.Magnitude * 1.7), center.Position)
        viewport.CurrentCamera = camera
        return true
    end
    local function preview(item)
        local body = openModal(item.title ~= "" and item.title or item.name)
        local hasModel = flags.Preview3D and modelPreview(body, item)
        if not hasModel then image(body, item, UDim2.new(0.5, -80, 0, 0), UDim2.fromOffset(160, 160)) end
        local details = item.rarity .. " / Item ID " .. item.id .. "\n" .. item.idType .. " / " .. item.category
        details ..= hasModel and "\nLocal model preview" or "\nIcon preview"
        text(body, "Details", details, UDim2.fromOffset(4, 186), UDim2.new(1, -8, 0, 80), 13)
        text(body, "Description", item.description, UDim2.fromOffset(4, 274), UDim2.new(1, -8, 0, 100), 12, true)
        tell("Viewing: " .. item.name)
    end
    local function settings()
        local body = openModal("Utilities")
        for index, key in ipairs({"Visual", "Balance", "Gift Perm", "Icons", "Preview3D"}) do
            local control
            control = button(body, "Toggle" .. key, key .. ": " .. (flags[key] and "ON" or "OFF"),
                UDim2.fromOffset(4, (index - 1) * 52), UDim2.new(1, -8, 0, 44), function()
                    flags[key] = not flags[key]
                    control.Text = key .. ": " .. (flags[key] and "ON" or "OFF")
                    gui:SetAttribute("Enabled" .. key:gsub(" ", ""), flags[key])
                    if tab == key and not flags[key] then tab = "Inventory"; category = "Fruits" end
                    render()
                end)
        end
    end
    button(panel, "Settings", "Tools", UDim2.new(1, -194, 0, 4), UDim2.fromOffset(64, 38), settings)
    local function showGift(item)
        local body = openModal("Gift Perm simulation")
        text(body, "GiftItem", item.name .. " / ID " .. item.id, UDim2.fromOffset(4, 4), UDim2.new(1, -8, 0, 50), 15)
        local recipient = box(body, "Recipient", "Recipient username", UDim2.fromOffset(4, 66), UDim2.new(1, -8, 0, 44))
        button(body, "RecordGift", "Record simulated gift", UDim2.fromOffset(4, 126), UDim2.new(1, -8, 0, 44), function()
            if Inventory.gift(state, item, recipient.Text) then
                gui:SetAttribute("GiftCount", #state.gifts)
                closeModal(); tell("Simulated gift recorded for " .. state.gifts[1].recipient)
            else tell("Use a username of 3–20 letters, digits or underscores.") end
        end, colors.green)
        text(body, "Scope", "Gifts are recorded inside this simulator.", UDim2.fromOffset(4, 190), UDim2.new(1, -8, 0, 55), 12, true)
    end
    updateQuantity = function()
        local count = 0
        for _, row in pairs(state.items) do count += row.count end
        gui:SetAttribute("LocalQuantity", count)
    end

    render = function()
        if not alive then return end
        nav:ClearAllChildren(); tabs:ClearAllChildren(); content:ClearAllChildren(); footer:ClearAllChildren()
        content.CanvasPosition = Vector2.zero
        gui:SetAttribute("Tab", tab); gui:SetAttribute("Category", category)
        local navigation = {"Inventory", "Added"}
        for _, key in ipairs({"Visual", "Balance", "Gift Perm"}) do
            if flags[key] then table.insert(navigation, key) end
        end
        for index, key in ipairs(navigation) do
            button(nav, key, key, UDim2.fromScale((index - 1) / #navigation, 0), UDim2.new(1 / #navigation, -4, 1, 0), function()
                tab = key; category = key == "Visual" and "Swords" or key == "Gift Perm" and "Permanent" or "Fruits"
                page = 1; query = ""; search.Text = ""; render()
            end, key == tab and colors.edge or nil)
        end
        search.Visible = tab ~= "Balance"
        if tab == "Balance" then
            text(content, "BalanceScope", "Balance simulation", UDim2.fromOffset(4, 0), UDim2.new(1, -8, 0, 26), 15)
            text(content, "BeliLabel", "Beli", UDim2.fromOffset(4, 36), UDim2.new(1, -8, 0, 20), 12, true)
            local beli = box(content, "Beli", "Beli", UDim2.fromOffset(4, 60), UDim2.new(1, -8, 0, 44))
            text(content, "FragmentsLabel", "Fragments", UDim2.fromOffset(4, 116), UDim2.new(1, -8, 0, 20), 12, true)
            local fragments = box(content, "Fragments", "Fragments", UDim2.fromOffset(4, 140), UDim2.new(1, -8, 0, 44))
            beli.Text, fragments.Text = tostring(state.balance.beli), tostring(state.balance.fragments)
            button(content, "SaveBalance", "Save local balance", UDim2.fromOffset(4, 204), UDim2.new(1, -8, 0, 44), function()
                if Inventory.setBalance(state, beli.Text, fragments.Text) then
                    gui:SetAttribute("Beli", state.balance.beli); gui:SetAttribute("Fragments", state.balance.fragments)
                    tell("Simulation balance saved.")
                else tell("Enter whole numbers from 0 to 9007199254740991.") end
            end, colors.green)
            button(content, "ResetBalance", "Reset balance", UDim2.fromOffset(4, 262), UDim2.new(1, -8, 0, 44), function()
                Inventory.setBalance(state, "0", "0"); gui:SetAttribute("Beli", 0); gui:SetAttribute("Fragments", 0); render()
            end)
            return
        end
        local categoryTabs = tab == "Inventory" and {"Fruits", "Permanent", "Fruit Skins", "Premium"}
            or tab == "Visual" and {"Swords", "Guns", "Skills"} or {}
        for index, key in ipairs(categoryTabs) do
            button(tabs, key, key, UDim2.fromScale((index - 1) / #categoryTabs, 0), UDim2.new(1 / #categoryTabs, -4, 1, 0), function()
                category = key; page = 1; render()
            end, category == key and accents[key] or nil)
        end
        local rows = {}
        if tab == "Added" then
            for _, row in pairs(state.items) do
                if Catalog.matches(row.item, query) then table.insert(rows, row.item) end
            end
            table.sort(rows, function(a, b) return a.name:lower() < b.name:lower() end)
            button(tabs, "ClearAll", "Clear Whole Inventory", UDim2.new(), UDim2.new(0.63, -4, 1, 0), function()
                local ok, err = Inventory.clear(state)
                updateQuantity(); render(); tell(ok and "Local inventory cleared. Undo Clear is available." or ("Clear failed: " .. tostring(err)))
            end, colors.red)
            button(tabs, "UndoClear", "Undo Clear", UDim2.fromScale(0.64, 0), UDim2.new(0.36, -4, 1, 0), function()
                local ok, err = Inventory.undoClear(state); updateQuantity(); render()
                tell(ok and "Last cleared batch restored." or tostring(err or "Nothing to undo."))
            end)
        else
            rows = Catalog.search(query, category)
        end
        gui:SetAttribute("ResultCount", #rows)
        -- shortcut: 30 cards per page bounds UI instances; virtualize if larger pages are needed.
        local pages = math.max(1, math.ceil(#rows / 30))
        page = math.clamp(page, 1, pages)
        button(footer, "Previous", "<", UDim2.new(), UDim2.new(0.12, 0, 1, 0), function() page -= 1; render() end)
        text(footer, "Page", page .. " / " .. pages .. " • " .. #rows .. " items", UDim2.fromScale(0.14, 0), UDim2.new(0.37, 0, 1, 0), 11, true)
        button(footer, "Next", ">", UDim2.fromScale(0.52, 0), UDim2.new(0.12, 0, 1, 0), function() page += 1; render() end)
        if tab == "Gift Perm" then
            button(footer, "History", "History", UDim2.fromScale(0.67, 0), UDim2.new(0.33, 0, 1, 0), function()
                local body = openModal("Simulated gift history")
                local lines = {}
                for _, gift in ipairs(state.gifts) do table.insert(lines, gift.name .. " → " .. gift.recipient) end
                text(body, "History", #lines > 0 and table.concat(lines, "\n") or "No simulated gifts.", UDim2.fromOffset(4, 0), UDim2.new(1, -8, 0, math.max(60, #lines * 44)), 13)
            end)
        elseif tab == "Visual" then
            button(footer, "RestoreVisual", "Restore visuals", UDim2.fromScale(0.67, 0), UDim2.new(0.33, 0, 1, 0), function()
                for id, row in pairs(state.items) do
                    if row.visual then
                        if state.native then
                            local ok, err = state.native:sync(row.item, row.count, false, false)
                            if not ok then tell("Restore failed: " .. tostring(err)); return end
                        end
                        equipment:remove(id); row.visual = nil
                    end
                end
                state.visualId = nil; gui:SetAttribute("VisualItemId", nil); closeModal(); tell("Visual selection cleared.")
            end)
        else
            button(footer, "Rescan", "Rescan", UDim2.fromScale(0.67, 0), UDim2.new(0.33, 0, 1, 0), refreshModels)
        end
        local columns = panel.AbsoluteSize.X < 480 and 1 or 2
        make("UIGridLayout", content, {CellSize = UDim2.new(1 / columns, -8, 0, 132),
            CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder})
        if #rows == 0 then
            text(content, "Empty", "No matching items", UDim2.new(), UDim2.new(1, -8, 0, 116), 15, true)
        end
        for index = (page - 1) * 30 + 1, math.min(page * 30, #rows) do
            local item = rows[index]
            local source = sourceFor(item)
            local stock = state.items[item.id]
            local available = (source and source.Parent and source:FindFirstChildWhichIsA("BasePart", true))
                or Equipment.findExistingTool(player, item) or (stock and stock.tool and stock.tool.Parent) or fruitModels:path(item)
            local card = make("Frame", content, {Name = "Item_" .. item.id, LayoutOrder = index,
                BackgroundColor3 = available and colors.available or colors.surface, BorderSizePixel = 0})
            card:SetAttribute("ItemId", item.id); round(card, false)
            if flags.Icons then image(card, item, UDim2.fromOffset(8, 8), UDim2.fromOffset(58, 58)) end
            local left = flags.Icons and 74 or 10
            text(card, "Name", item.title ~= "" and item.title or item.name, UDim2.fromOffset(left, 6), UDim2.new(1, -left - 8, 0, 50), 12)
            text(card, "Metadata", item.rarity .. " • " .. item.id, UDim2.fromOffset(10, 64), UDim2.new(1, -20, 0, 16), 10, true)
            if tab == "Added" then
                text(card, "Count", "×" .. state.items[item.id].count, UDim2.fromOffset(10, 88), UDim2.new(0.4, 0, 0, 22), 12)
                button(card, "Equip", available and "Equip" or "No model", UDim2.new(1, -168, 1, -48), UDim2.fromOffset(76, 42), function() equip(item) end, available and colors.green or colors.surface)
                button(card, "Clear", "Clear", UDim2.new(1, -84, 1, -48), UDim2.fromOffset(76, 42), function()
                    local ok, err = Inventory.clear(state, item.id)
                    updateQuantity(); render(); tell(ok and "Item cleared from the local inventory." or ("Clear failed: " .. tostring(err)))
                end, colors.red)
            else
                button(card, "Details", "View", UDim2.fromOffset(8, 84), UDim2.fromOffset(60, 42), function() preview(item) end)
                button(card, "Action", tab == "Visual" and (available and "Equip" or "No model") or tab == "Gift Perm" and "Gift" or "+ Add",
                    UDim2.new(1, -94, 1, -48), UDim2.fromOffset(86, 42), function()
                        if tab == "Visual" then useVisual(item)
                        elseif tab == "Gift Perm" then showGift(item)
                        else
                            local ok, err = Inventory.add(state, item)
                            if ok then
                                updateQuantity()
                                tell((state.native and "Added to Items locally: " or "Added to panel only / Items offline: ") .. item.name)
                            else
                                tell("Add failed: " .. tostring(err))
                                warn("[Blox Catalog] " .. status.Text)
                                if state.native and state.native.lastFailure and typeof(writefile) == "function" then
                                    local failure = {schemaVersion = 1, placeId = game.PlaceId, placeVersion = game.PlaceVersion, write = state.native.lastFailure}
                                    pcall(writefile, "blox-catalog-native-error-" .. game.PlaceId .. ".json", game:GetService("HttpService"):JSONEncode(failure))
                                end
                            end
                        end
                    end, tab == "Visual" and not available and colors.surface or colors.green)
            end
        end
    end

    refreshModels = function()
        if scanning or not alive then return end
        scanning = true
        task.spawn(function()
            if not state.native then
                local linked, bridge = pcall(NativeItems.connect, equip)
                if linked then
                    -- The GUI may close while cached imports are yielding.
                    if not alive then bridge:close(); return end
                    local synced, syncError = true, nil
                    for _, row in pairs(state.items) do
                        synced, syncError = bridge:sync(row.item, row.count, row.tool and row.tool.Parent ~= nil, row.equipped)
                        if not synced then break end
                    end
                    if synced then
                        state.native = bridge; state.nativeError = nil
                        print("[Blox Catalog] Native Items linked locally")
                    else
                        local cleaned = bridge:close()
                        if not cleaned then state.native = bridge end
                        state.nativeError = tostring(syncError)
                    end
                else state.nativeError = tostring(bridge) end
            end
            local storage = game:GetService("ReplicatedStorage")
            local roots = {}
            for _, root in pairs({storage:FindFirstChild("HybridDownloadedFruitTemplates"),
                player:FindFirstChild("Backpack"), player.Character, playerGui:FindFirstChild("WeaponAssetCache")}) do
                table.insert(roots, root)
            end
            for _, node in ipairs(workspace:GetChildren()) do
                if node:IsA("Tool") then table.insert(roots, node) end
            end
            local found, visited = {}, 0
            for _, root in ipairs(roots) do
                local queue, head = {root}, 1
                while queue[head] and visited < 3000 and alive do
                    local node = queue[head]; head += 1; visited += 1
                    if not node:GetAttribute("BloxCatalogOwned") and (node:IsA("Tool") or node:IsA("Model")) then
                        local id = tostring(node:GetAttribute("ItemId") or "")
                        if id == "" and node:IsA("Tool") then id = Catalog.byToolName[node.Name] or "" end
                        if Catalog.byId[id] then
                            found[id] = node
                            if node:IsA("Tool") and (node.Parent == player.Character or node.Parent == player:FindFirstChildOfClass("Backpack")) then
                                fruitModels:capture(Catalog.byId[id],node)
                            end
                        end
                    end
                    for _, child in ipairs(node:GetChildren()) do
                        if #queue >= 3000 then break end
                        if not node:GetAttribute("BloxCatalogOwned") and not child:IsA("LuaSourceContainer") and not child:IsA("BasePart") then table.insert(queue, child) end
                    end
                    if visited % 100 == 0 then task.wait() end
                end
            end
            scanning = false
            if not alive then return end
            models = found
            info.Text = Catalog.count .. " records / " .. (state.native and "Items linked locally" or "Items offline / panel only")
            info:SetAttribute("ItemsLinked", state.native ~= nil)
            if tab ~= "Balance" then render() end
            local modelCount = 0
            for _ in pairs(found) do modelCount += 1 end
            tell(state.nativeError and ("Items offline: " .. state.nativeError) or ("Items linked locally / " .. modelCount .. " models available"))
            print("[Blox Catalog] " .. status.Text)
        end)
    end
    table.insert(connections, search:GetPropertyChangedSignal("Text"):Connect(function()
        query = search.Text; page = 1; render()
    end))
    table.insert(connections, player.CharacterAdded:Connect(function()
        equipment:close()
        for _, row in pairs(state.items) do
            if state.native then
                local ok, err = state.native:sync(row.item, row.count, false, false)
                if not ok then tell(tostring(err)) end
            end
        end
        refreshModels()
    end))
    table.insert(connections, Input.InputBegan:Connect(function(key, processed)
        if processed or Input:GetFocusedTextBox() then return end
        if key.KeyCode == Enum.KeyCode.Escape then closeModal()
        elseif key.KeyCode == Enum.KeyCode.RightShift then panel.Visible = not panel.Visible; openButton.Visible = not panel.Visible
        elseif key.KeyCode == Enum.KeyCode.F6 then refreshModels() end
    end))
    local dragging, origin, start, moved
    local function clamp(position)
        local bounds, size = gui.AbsoluteSize, panel.AbsoluteSize
        return UDim2.fromOffset(math.clamp(position.X.Scale * bounds.X + position.X.Offset, size.X / 2, math.max(size.X / 2, bounds.X - size.X / 2)),
            math.clamp(position.Y.Scale * bounds.Y + position.Y.Offset, size.Y / 2, math.max(size.Y / 2, bounds.Y - size.Y / 2)))
    end
    table.insert(connections, drag.InputBegan:Connect(function(key)
        if key.UserInputType == Enum.UserInputType.MouseButton1 or key.UserInputType == Enum.UserInputType.Touch then
            dragging, origin, start = key, key.Position, panel.Position
        end
    end))
    table.insert(connections, Input.InputChanged:Connect(function(key)
        if dragging and (key == dragging or key.UserInputType == Enum.UserInputType.MouseMovement and dragging.UserInputType == Enum.UserInputType.MouseButton1) then
            local delta = key.Position - origin; moved = true
            panel.Position = clamp(start + UDim2.fromOffset(delta.X, delta.Y))
        end
    end))
    table.insert(connections, Input.InputEnded:Connect(function(key)
        if key == dragging then dragging = nil end
    end))
    local function resize()
        local size = gui.AbsoluteSize
        local width = math.min(620, math.max(200, size.X - 20))
        panel.Size = UDim2.fromOffset(width, math.min(760, math.max(260, size.Y - 20)))
        local compact = size.Y < 540
        nav.Position = UDim2.fromOffset(12, 48); nav.Size = UDim2.new(1, -24, 0, compact and 30 or 38)
        info.Visible = not compact; info.Position = UDim2.fromOffset(14, 92); info.Size = UDim2.new(1, -28, 0, 18)
        search.Position = UDim2.fromOffset(12, compact and 86 or 116); search.Size = UDim2.new(1, -24, 0, compact and 32 or 40)
        tabs.Position = UDim2.fromOffset(12, compact and 124 or 164); tabs.Size = UDim2.new(1, -24, 0, compact and 32 or 38)
        content.Position = UDim2.fromOffset(12, compact and 164 or 210); content.Size = UDim2.new(1, -24, 1, compact and -224 or -274)
        footer.Position = UDim2.new(0, 12, 1, -58); footer.Size = UDim2.new(1, -24, 0, 34)
        status.Position = UDim2.new(0, 14, 1, -22); status.Size = UDim2.new(1, -28, 0, 20)
        panel.Position = moved and clamp(panel.Position) or UDim2.fromScale(0.5,0.5)
        render()
    end
    table.insert(connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
    gui.Destroying:Connect(function()
        alive = false
        equipment:close(true)
        fruitModels:close()
        nativeEquip:close()
        if nativeDialogue then nativeDialogue:close() end
        if state.native then
            local called, ok, err = pcall(state.native.close, state.native)
            if not called or not ok then warn("[Blox Catalog] Native restore failed: " .. tostring(called and err or ok)) end
        end
        for _, connection in ipairs(connections) do connection:Disconnect() end
        table.clear(models)
    end)
    resize(); refreshModels()
    return gui
end

return UI
