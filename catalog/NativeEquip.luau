local NativeEquip = {}

function NativeEquip.new(playerGui,state,onEquip)
    local binding = {}
    local overlay, original, connection
    local function normalized(text)
        return text:gsub("<[^>]*>",""):gsub("%s+"," "):match("^%s*(.-)%s*$"):lower()
    end
    local function selected()
        local main=playerGui:FindFirstChild("Main")
        local inventory=main and main:FindFirstChild("InventoryContainer")
        local left=inventory and inventory:FindFirstChild("Left")
        local label=left and left:FindFirstChild("ItemName")
        local button=left and left:FindFirstChild("Equip")
        if not label or not label:IsA("TextLabel") or not button or not button:IsA("GuiButton") then return nil end
        local name=normalized(label.Text)
        local match
        for _,row in pairs(state.items) do
            local entry=state.native and state.native.entries[tonumber(row.item.id)]
            if row.item.category=="Fruits" and entry and not (typeof(entry.original)=="number" and entry.original>0)
                and normalized(row.item.name)==name then
                if match then return nil end
                match=row.item
            end
        end
        return match,button
    end
    local function clear()
        if connection then connection:Disconnect();connection=nil end
        if overlay then overlay:Destroy();overlay=nil end
        original=nil
    end
    function binding:refresh()
        if self.closed then return end
        local item,button=selected()
        if not item then clear();return end
        if original~=button or not overlay or not overlay.Parent then
            clear()
            original=button
            -- Only simulated fruit selections cover the legacy callback; real selections keep the original button.
            overlay=Instance.new("TextButton")
            overlay.Name="BloxCatalogEquip"
            overlay.Text=""
            overlay.BackgroundTransparency=1
            overlay.AutoButtonColor=false
            overlay:SetAttribute("LocalSimulation",true)
            overlay.Parent=button.Parent
            connection=overlay.Activated:Connect(function()
                local current,currentButton=selected()
                if current and currentButton==original then onEquip(current) end
            end)
        end
        overlay.AnchorPoint=button.AnchorPoint
        overlay.Position=button.Position
        overlay.Size=button.Size
        overlay.Rotation=button.Rotation
        overlay.ZIndex=button.ZIndex+1
        overlay.Visible=button.Visible
        overlay.Selectable=button.Selectable
    end
    function binding:close()
        self.closed=true
        clear()
    end
    return binding
end

return NativeEquip
