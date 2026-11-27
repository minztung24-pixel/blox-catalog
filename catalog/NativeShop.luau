local RobloxPrompt = require(script.Parent.RobloxPrompt)
local Catalog = require(script.Parent.Catalog)
local Inventory = require(script.Parent.Inventory)
local Collection=game:GetService("CollectionService")
local Run=game:GetService("RunService")
local NativeShop={}

function NativeShop.new(playerGui,state,onChange,enabled)
    local binding={phase="Idle"}
    local original,overlay,connection,savedVisible,savedInteractable,savedSelectable
    local checkout,view,quote,processing,heartbeat
    local elapsed,dotElapsed,dots=0,0,0
    local function closeDialog(animated)
        if view then view:close(animated);view=nil end
        checkout=nil
    end
    local function restoreProcessing()
        if not processing then return end
        local p=processing;processing=nil
        if p.overlay.Parent then p.overlay.Visible=p.visible end
        if p.text.Parent then p.text.Text=p.caption end
        if p.image.Parent then
            p.image.Image=p.sprite;p.image.ImageRectOffset=p.offset;p.image.ImageRectSize=p.size;p.image.Rotation=p.rotation
        end
    end
    local function dismiss(animated)
        closeDialog(animated);restoreProcessing();quote=nil;binding.phase="Idle";elapsed=0
    end
    local function startProcessing(frame,item)
        local native=frame:FindFirstChild("Overlay")
        local loading=native and native:FindFirstChild("Loading")
        local image=loading and loading:FindFirstChild("ImageLabel")
        local text=loading and loading:FindFirstChild("TextLabel")
        if not native or not native:IsA("GuiObject") or not image or not image:IsA("ImageLabel")
            or not text or not text:IsA("TextLabel")then return false,"Native Processing Purchase UI unavailable. Reopen Gift." end
        if native.Visible then return false,"Gift is busy. Wait for its current operation." end
        processing={overlay=native,visible=native.Visible,image=image,sprite=image.Image,offset=image.ImageRectOffset,
            size=image.ImageRectSize,rotation=image.Rotation,text=text,caption=text.Text}
        image.Image=item.icon;image.ImageRectOffset=item.iconRectOffset and Vector2.new(table.unpack(item.iconRectOffset))or Vector2.zero
        image.ImageRectSize=item.iconRectSize and Vector2.new(table.unpack(item.iconRectSize))or Vector2.zero
        image.Rotation=0;text.Text="Processing Purchase";native.Visible=true
        dotElapsed=0;dots=0
        return true
    end
    local function window(includeHidden)
        local gui=playerGui:FindFirstChild("GiftWindow")
        local frame=gui and gui:FindFirstChild("Window")
        if not frame or not frame:IsA("GuiObject") then return nil end
        local node=frame
        while node and node~=playerGui do
            if not includeHidden and (node:IsA("GuiObject") and not node.Visible or node:IsA("ScreenGui") and not node.Enabled)then return nil end
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
        dismiss()
        if connection then connection:Disconnect();connection=nil end
        if overlay then overlay:Destroy();overlay=nil end
        if original and original.Parent then
            original.Visible=savedVisible;original.Interactable=savedInteractable;original.Selectable=savedSelectable
        end
        original=nil
    end
    local function active()
        return not binding.closed and state.balance.applied and enabled()
    end
    local function closeNativeGift(q)
        task.spawn(function()
            if quote~=q or not active()or not q.screen or not q.screen.Parent or q.screen.Enabled then return end
            -- Native Cancel calls Close(onClose); calling Close alone leaves the shop's gift lock set.
            if type(getconnections)=="function" and q.cancel and q.cancel.Parent and q.cancel:IsA("GuiButton")then
                local ok,handler=pcall(function()
                    local found
                    for _,entry in ipairs(getconnections(q.cancel.Activated))do
                        if entry.Enabled~=false and type(entry.Function)=="function"then
                            if found then return nil end
                            found=entry.Function
                        end
                    end
                    return found
                end)
                if ok and handler and pcall(handler)then
                    q.screen:SetAttribute("BloxCatalogClosePath","NativeCancel")
                    return
                end
            end
            -- shortcut: without readable Cancel connections, use Close until the controller exposes its owner's onClose callback.
            local controllers=game:GetService("ReplicatedStorage"):FindFirstChild("Controllers")
            local ui=controllers and controllers:FindFirstChild("UI")
            local module=ui and ui:FindFirstChild("GiftWindow")
            if not module or not module:IsA("ModuleScript")then return end
            local loaded,controller=pcall(require,module)
            if loaded and quote==q and active()and q.screen.Parent and not q.screen.Enabled
                and type(controller)=="table" and type(controller.Close)=="function"then
                pcall(controller.Close,controller)
                q.screen:SetAttribute("BloxCatalogClosePath","ControllerFallback")
            end
        end)
    end
    local function show(completed)
        local q=quote
        view=RobloxPrompt.open(playerGui,{
            productName=q.item.name.." - Gift",icon=q.item.icon,
            iconRectOffset=q.item.iconRectOffset,iconRectSize=q.item.iconRectSize,
            balance=state.balance.robux,price=q.price,cost=q.cost,
            discountLabel=q.discount and ("Saving "..(q.price-q.cost).." with Plus")or nil,
            resultText="You have successfully bought "..q.item.name.." for "..q.username.."."
        },completed,function()binding:confirm()end,function()binding:cancel(true)end)
        checkout=view.gui
        binding.phase=completed and "Completed"or "Confirm";elapsed=0
    end
    function binding:cancel(animated)
        dismiss(animated)
    end
    local function quoteMatches(button,item,username,price)
        return quote and button==quote.button and item==quote.item and username==quote.username
            and price==quote.price and state.balance==quote.balance and state.balance.robux==quote.available
            and state.balance.plusDiscount==quote.discount
    end
    local function validQuote()
        local frame=active() and window()
        if not frame then return false end
        local button,_,item,username,price=selection(frame)
        return quoteMatches(button,item,username,price)
    end
    function binding:step(dt)
        if type(dt)~="number" or dt<0 or dt~=dt or dt==math.huge then return end
        if view then view:step(dt)end
        if self.closed or not quote or self.phase=="Completed"then return end
        if not validQuote()then dismiss();onChange("Selection or balance changed. Open Gift again.");return end
        elapsed+=dt
        if processing then
            dotElapsed+=dt
            if dotElapsed>=.33 then
                dotElapsed%=.33;dots=dots%3+1
                processing.text.Text="Processing Purchase"..string.rep(".",dots)
            end
        end
        if self.phase=="Preparing" and elapsed>=.33 then
            -- Local preview has no server wait: show one authored processing-dot interval first.
            show(false)
        elseif self.phase=="Purchasing" and elapsed>=.33 then
            local q=quote
            restoreProcessing()
            local ok,message=Inventory.buyGift(state,q.item,q.username,q.price)
            if ok then
                show(true)
                if q.screen and q.screen.Parent then q.screen.Enabled=false end
                closeNativeGift(q)
                message="Simulated gift: "..q.item.name.." → "..q.username..". Not delivered."
            else dismiss()end
            onChange(message,ok and "Gift sent successfully"or nil)
        end
    end
    function binding:confirm()
        if not quote or not view or self.phase~="Confirm" or not view:ready()then return false end
        if not validQuote()then
            dismiss();onChange("Selection or balance changed. Open Gift again.");return false
        end
        closeDialog(true);self.phase="Purchasing";elapsed=0
        onChange("Sending local gift preview to "..quote.username.."...","Sending gift to "..quote.username.."...")
        return true
    end
    function binding:buy()
        if quote then return false,"Close the current checkout first." end
        local frame=active() and window()
        if not frame then return false end
        local button,_,item,username,price=selection(frame)
        local message="Select a player and a supported permanent fruit."
        if button==original and item and username then
            local cost=Inventory.shopPrice(state,price)
            if not cost then message="Shop price unavailable."
            elseif #username<3 or #username>20 then message="Invalid gift recipient."
            elseif cost>state.balance.robux then message="Insufficient visual Robux."
            else
                local ok,err=startProcessing(frame,item)
                if not ok then onChange(err);return false,err end
                quote={button=button,item=item,username=username,price=price,cost=cost,
                    discount=state.balance.plusDiscount,balance=state.balance,available=state.balance.robux,
                    cancel=frame.Content.Buttons:FindFirstChild("Cancel"),
                    screen=frame:FindFirstAncestorWhichIsA("ScreenGui")}
                self.phase="Preparing";elapsed=0;return true
            end
        end
        onChange(message)
        return false,message
    end
    function binding:refresh()
        if active()and self.phase=="Completed"then
            if not window()then return end
            dismiss()
        end
        local frame=active() and window(true)
        if not frame then clear();return end
        -- Keep the real button covered while Gift is hidden, so reopening stays in preview mode.
        if not window()then dismiss()end
        local button,label,item,username,price=selection(frame)
        if not button then clear();return end
        if quote and not quoteMatches(button,item,username,price)then
            dismiss()
        end
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
        end
        original.Visible=false;original.Interactable=false;original.Selectable=false
        overlay.Visible=savedVisible
        overlay.Position=button.Position;overlay.Size=button.Size;overlay.AnchorPoint=button.AnchorPoint
        overlay.Rotation=button.Rotation;overlay.ZIndex=button.ZIndex
        overlay.BackgroundColor3=button.BackgroundColor3;overlay.BackgroundTransparency=button.BackgroundTransparency
        local trans=button:FindFirstChild("Trans")
        local copy=overlay:FindFirstChild("Trans")
        if trans and copy and trans:IsA("Frame") and copy:IsA("Frame")then
            copy.BackgroundColor3=trans.BackgroundColor3;copy.BackgroundTransparency=trans.BackgroundTransparency
        end
        overlay.TextLabel.Text=label.Text
    end
    function binding:close()
        if heartbeat then heartbeat:Disconnect();heartbeat=nil end
        self.closed=true;clear()
    end
    if Run:IsRunning() and Run:IsClient()then heartbeat=Run.Heartbeat:Connect(function(dt)binding:step(dt)end)end
    return binding
end
return NativeShop
