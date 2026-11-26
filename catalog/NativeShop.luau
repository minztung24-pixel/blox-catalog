local Catalog = require(script.Parent.Catalog)
local Inventory = require(script.Parent.Inventory)
local Collection=game:GetService("CollectionService")
local NativeShop={}

function NativeShop.new(playerGui,state,onChange,enabled)
    local binding={}
    local original,overlay,badge,connection,savedVisible,savedInteractable,savedSelectable
    local function window()
        local gui=playerGui:FindFirstChild("GiftWindow")
        local frame=gui and gui:FindFirstChild("Window")
        if not frame or not frame:IsA("GuiObject") then return nil end
        local node=frame
        while node and node~=playerGui do
            if node:IsA("GuiObject") and not node.Visible or node:IsA("ScreenGui") and not node.Enabled then return nil end
            node=node.Parent
        end
        return frame
    end
    local function selection(frame)
        local footer=frame:FindFirstChild("Footer")
        local context=footer and footer:FindFirstChild("Context")
        local content=frame:FindFirstChild("Content")
        local buttons=content and content:FindFirstChild("Buttons")
        local button=buttons and buttons:FindFirstChild("Purchase")
        local label=button and button:FindFirstChild("TextLabel")
        if not button or not button:IsA("GuiButton") or not label or not label:IsA("TextLabel") then return nil end
        local username,name
        if context and context:IsA("TextLabel")then
            username=context.Text:match("^Gifting%s*%[([A-Za-z0-9_]+)%]")
            name=context.Text:match("<([^<>]+)>%s*$")
            -- The observed native context appends a literal } inside the product delimiter.
            if name then name=name:gsub("}%s*$",""):match("^%s*(.-)%s*$")end
        end
        local item
        for _,candidate in ipairs(Catalog.search("","Permanent"))do
            if candidate.name==name then
                if item then item=nil;break end
                item=candidate
            end
        end
        local plain=label.Text:gsub("<[^>]*>","")
        local digits=plain:match("(%d[%d,%s]*)%s*$")
        local price=digits and tonumber((digits:gsub("[,%s]","")))
        return button,label,item,username,price
    end
    local function clear()
        if connection then connection:Disconnect();connection=nil end
        if overlay then overlay:Destroy();overlay=nil end
        if badge then badge:Destroy();badge=nil end
        if original and original.Parent then
            original.Visible=savedVisible;original.Interactable=savedInteractable;original.Selectable=savedSelectable
        end
        original=nil
    end
    local function active()
        return not binding.closed and state.balance.applied and enabled()
    end
    function binding:buy()
        local frame=active() and window()
        if not frame then return false end
        local button,_,item,username,price=selection(frame)
        local ok,message=false,"Select a player and a supported permanent fruit."
        if button==original and item and username then
            ok,message=Inventory.buyGift(state,item,username,price)
            if ok then message="Simulated gift: "..item.name.." → "..username..". Not delivered." end
        end
        if badge then badge.Text=message end
        onChange(message)
        return ok,message
    end
    function binding:refresh()
        local frame=active() and window()
        if not frame then clear();return end
        local button,label,item,username,price=selection(frame)
        if not button then clear();return end
        if original~=button or not overlay or not overlay.Parent then
            clear()
            local clone=button:Clone()
            if not clone then return end
            for _,node in ipairs(clone:GetDescendants())do
                if node:IsA("LuaSourceContainer") or node:IsA("RemoteEvent") or node:IsA("RemoteFunction")
                    or node:IsA("BindableEvent") or node:IsA("BindableFunction")then node:Destroy()end
            end
            for _,node in ipairs(clone:GetDescendants())do
                for _,tag in ipairs(Collection:GetTags(node))do Collection:RemoveTag(node,tag)end
            end
            for _,tag in ipairs(Collection:GetTags(clone))do Collection:RemoveTag(clone,tag)end
            original=button;overlay=clone
            savedVisible,savedInteractable,savedSelectable=button.Visible,button.Interactable,button.Selectable
            overlay.Name="BloxCatalogVisualPurchase"
            overlay:SetAttribute("LocalSimulation",true)
            overlay.Interactable=true;overlay.Active=true;overlay.Selectable=true
            overlay.Parent=button.Parent
            connection=overlay.Activated:Connect(function()self:buy()end)
            badge=Instance.new("TextLabel")
            badge.Name="BloxCatalogGiftStatus";badge.Position=UDim2.new(0,0,1,4);badge.Size=UDim2.new(1,0,0,42)
            badge.BackgroundColor3=Color3.fromRGB(20,20,25);badge.BackgroundTransparency=.1
            badge.TextColor3=Color3.fromRGB(255,226,79);badge.Font=Enum.Font.GothamMedium
            badge.TextSize=12;badge.TextWrapped=true;badge.ZIndex=frame.ZIndex+6
            badge.Text="Visual R$: "..state.balance.robux.." · Local preview only"
            badge.Parent=frame.Footer.Context
        end
        original.Visible=false;original.Interactable=false;original.Selectable=false
        overlay.Visible=savedVisible
        overlay.Position=button.Position;overlay.Size=button.Size;overlay.AnchorPoint=button.AnchorPoint
        overlay.Rotation=button.Rotation;overlay.ZIndex=button.ZIndex+1
        overlay.BackgroundColor3=button.BackgroundColor3;overlay.BackgroundTransparency=button.BackgroundTransparency
        local trans=button:FindFirstChild("Trans")
        local copy=overlay:FindFirstChild("Trans")
        if trans and copy and trans:IsA("Frame") and copy:IsA("Frame")then
            copy.BackgroundColor3=trans.BackgroundColor3;copy.BackgroundTransparency=trans.BackgroundTransparency
        end
        local cost=Inventory.shopPrice(state,price)
        overlay.TextLabel.Text=item and username and cost and (label.Text:gsub("%d[%d,%s]*%s*$",tostring(cost).." · Visual"))
            or "Select gift / player · Visual"
    end
    function binding:close()
        self.closed=true;clear()
    end
    return binding
end
return NativeShop
