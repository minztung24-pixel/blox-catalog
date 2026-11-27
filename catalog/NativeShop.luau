local Catalog = require(script.Parent.Catalog)
local Inventory = require(script.Parent.Inventory)
local Collection=game:GetService("CollectionService")
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local NativeShop={}

function NativeShop.new(playerGui,state,onChange,enabled)
    local binding={phase="Idle"}
    local original,overlay,connection,savedVisible,savedInteractable,savedSelectable
    local checkout,quote,processing,heartbeat
    local elapsed,dotElapsed,dots=0,0,0
    local checkoutConnections={}
    local function closeDialog()
        for _,event in ipairs(checkoutConnections)do event:Disconnect()end
        table.clear(checkoutConnections)
        if checkout then checkout:Destroy();checkout=nil end
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
    local function dismiss()
        closeDialog();restoreProcessing();quote=nil;binding.phase="Idle";elapsed=0
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
    local function number(value)
        local formatted=string.format("%.0f",value)
        repeat
            local count
            formatted,count=formatted:gsub("^(%d+)(%d%d%d)","%1,%2")
            if count==0 then return formatted end
        until false
    end
    local function show(completed)
        local q=quote
        local height=completed and 280 or (q.discount and 344 or 264)
        local gui=Instance.new("ScreenGui")
        gui.Name="BloxCatalogCheckout";gui.ResetOnSpawn=false
        gui:SetAttribute("Simulation",true)
        gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
        local order=0
        for _,child in ipairs(playerGui:GetChildren())do
            if child:IsA("ScreenGui")then order=math.max(order,child.DisplayOrder)end
        end
        gui.DisplayOrder=order+1
        local shade=Instance.new("TextButton",gui)
        shade.Name="Shade";shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.new()
        shade.BackgroundTransparency=.4;shade.Text="";shade.AutoButtonColor=false;shade.Modal=true
        local panel=Instance.new("Frame",shade)
        panel.Name="Dialog";panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5)
        panel.Size=UDim2.fromOffset(456,height);panel.BackgroundColor3=Color3.fromRGB(25,26,31)
        panel.BorderSizePixel=0;panel.ZIndex=2
        local corner=Instance.new("UICorner",panel);corner.CornerRadius=UDim.new(0,16)
        local scale=Instance.new("UIScale",panel)
        local function fit()
            local camera=workspace.CurrentCamera
            local viewport=camera and camera.ViewportSize or Vector2.new(800,600)
            scale.Scale=math.min(1,math.max(1,viewport.X-24)/456,math.max(1,viewport.Y-100)/height)
        end
        fit()
        local camera=workspace.CurrentCamera
        if camera then table.insert(checkoutConnections,camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))end
        local function label(name,text,x,y,w,h,size)
            local node=Instance.new("TextLabel",panel)
            node.Name=name;node.Text=text;node.Position=UDim2.fromOffset(x,y);node.Size=UDim2.fromOffset(w,h)
            node.BackgroundTransparency=1;node.TextColor3=Color3.fromRGB(240,241,245)
            node.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json");node.TextSize=size or 18
            node.TextXAlignment=Enum.TextXAlignment.Left;node.TextWrapped=true;node.ZIndex=3
            return node
        end
        local function button(name,text,x,y,w,h,callback)
            local node=Instance.new("TextButton",panel)
            node.Name=name;node.Text=text;node.Position=UDim2.fromOffset(x,y);node.Size=UDim2.fromOffset(w,h)
            node.BackgroundColor3=Color3.fromRGB(51,95,255);node.TextColor3=Color3.new(1,1,1)
            node.TextSize=18;node.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json",Enum.FontWeight.Bold)
            node.BorderSizePixel=0;node.ZIndex=4
            Instance.new("UICorner",node).CornerRadius=UDim.new(0,8)
            table.insert(checkoutConnections,node.Activated:Connect(callback))
            return node
        end
        local function bold(node)
            node.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json",Enum.FontWeight.Bold)
            return node
        end
        local function robux(name,x,y,size)
            local icon=Instance.new("ImageLabel",panel)
            icon.Name=name;icon.Image="rbxasset://textures/ui/common/robux@3x.png"
            icon.Position=UDim2.fromOffset(x,y);icon.Size=UDim2.fromOffset(size,size)
            icon.BackgroundTransparency=1;icon.ZIndex=3
        end
        bold(label("Title",completed and "Purchase completed" or "Buy item",20,16,270,28,20))
        local close=button("Close","×",408,10,36,36,function()binding:cancel()end)
        close.BackgroundTransparency=1;close.TextSize=28
        if completed then
            local circle=Instance.new("Frame",panel)
            circle.Name="CheckCircle";circle.Position=UDim2.fromOffset(202,52);circle.Size=UDim2.fromOffset(52,52)
            circle.BackgroundTransparency=1;circle.ZIndex=3
            Instance.new("UICorner",circle).CornerRadius=UDim.new(1,0)
            local stroke=Instance.new("UIStroke",circle);stroke.Thickness=2;stroke.Color=Color3.fromRGB(220,222,228)
            local check=label("Check","✓",202,52,52,52,30);check.TextXAlignment=Enum.TextXAlignment.Center
            local result=label("Result","Simulated purchase of "..q.item.name.." for "..q.username.." completed.",20,126,416,52,14)
            result.TextXAlignment=Enum.TextXAlignment.Center
        else
            robux("BalanceIcon",308,21,18)
            local balance=bold(label("Balance",number(state.balance.robux),304,16,94,28,16))
            balance.TextXAlignment=Enum.TextXAlignment.Right
            local function alignBalance()
                panel.BalanceIcon.Position=UDim2.fromOffset(398-balance.TextBounds.X-24,21)
            end
            table.insert(checkoutConnections,balance:GetPropertyChangedSignal("TextBounds"):Connect(alignBalance))
            alignBalance()
            local icon=Instance.new("ImageLabel",panel)
            icon.Name="Icon";icon.Image=q.item.icon;icon.BackgroundTransparency=1
            icon.Position=UDim2.fromOffset(20,58);icon.Size=UDim2.fromOffset(72,72);icon.ZIndex=3
            if q.item.iconRectOffset then icon.ImageRectOffset=Vector2.new(table.unpack(q.item.iconRectOffset))end
            if q.item.iconRectSize then icon.ImageRectSize=Vector2.new(table.unpack(q.item.iconRectSize))end
            bold(label("Product",q.item.name.." - Gift",108,60,328,32,18))
            robux("PriceIcon",108,101,16)
            local amount=bold(label("Price",number(q.cost),132,94,160,28,18))
            if q.cost~=q.price then
                local old=bold(label("OriginalPrice","<s>"..number(q.price).."</s>",132,94,140,28,16))
                local function alignPrice()old.Position=UDim2.fromOffset(132+amount.TextBounds.X+16,94)end
                table.insert(checkoutConnections,amount:GetPropertyChangedSignal("TextBounds"):Connect(alignPrice))
                alignPrice()
                old.RichText=true;old.TextColor3=Color3.fromRGB(172,175,185)
            end
            if q.discount then
                local row=Instance.new("Frame",panel)
                row.Name="DiscountRow";row.Position=UDim2.fromOffset(20,154);row.Size=UDim2.fromOffset(416,56)
                row.BackgroundColor3=Color3.fromRGB(30,32,40);row.BorderSizePixel=0;row.ZIndex=2
                Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
                robux("DiscountIcon",36,173,18)
                bold(label("Discount","Saving "..number(q.price-q.cost).." with Plus",62,168,350,28,18))
            end
        end
        local primary=button(completed and "OK" or "Buy",completed and "OK" or "Buy",20,height-(completed and 80 or 110),416,40,function()
            if completed then binding:cancel()else binding:confirm()end
        end)
        if not completed then
            local caption=Instance.new("TextLabel",primary)
            caption.Name="Caption";caption.Text=primary.Text;primary.Text=""
            caption.Size=UDim2.fromScale(1,1);caption.BackgroundTransparency=1
            caption.FontFace=primary.FontFace;caption.TextSize=primary.TextSize
            caption.TextColor3=primary.TextColor3;caption.ZIndex=primary.ZIndex+1
            primary.Interactable=false;primary.AutoButtonColor=false
            local delay=Instance.new("UIGradient",primary);delay.Name="InputDelay"
            delay.Transparency=NumberSequence.new(.5)
            gui:SetAttribute("BuyReady",false);gui:SetAttribute("BuyProgress",0)
        end
        local scope=label("Scope","SIMULATION · No real Robux spent or gift delivered.",20,height-45,416,24,14)
        scope.TextColor3=Color3.fromRGB(180,183,193);scope.TextXAlignment=Enum.TextXAlignment.Center
        table.insert(checkoutConnections,Input.InputBegan:Connect(function(input)
            if input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB then binding:cancel()end
        end))
        gui:SetAttribute("Phase",completed and "Completed" or "Confirm")
        binding.phase=completed and "Completed" or "Confirm";elapsed=0
        checkout=gui;gui.Parent=playerGui
    end
    function binding:cancel()
        dismiss()
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
        if self.closed or not quote or self.phase=="Completed"then return end
        if type(dt)~="number" or dt<0 or dt~=dt or dt==math.huge then return end
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
        elseif self.phase=="Confirm"then
            local ready=elapsed>=2.5
            if ready and checkout:GetAttribute("BuyReady")then return end
            local progress=Tween:GetValue(math.clamp(elapsed/2.5,0,1),Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
            checkout:SetAttribute("BuyProgress",progress);checkout:SetAttribute("BuyReady",ready)
            local buy=checkout.Shade.Dialog.Buy
            buy.Interactable=ready;buy.AutoButtonColor=ready
            buy.InputDelay.Transparency=ready and NumberSequence.new(0)or NumberSequence.new({
                NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(math.max(0,progress-.0001),0),
                NumberSequenceKeypoint.new(math.min(1,progress+.0001),.5),NumberSequenceKeypoint.new(1,.5)})
        elseif self.phase=="Purchasing" and elapsed>=.33 then
            local q=quote
            restoreProcessing()
            local ok,message=Inventory.buyGift(state,q.item,q.username,q.price)
            if ok then
                show(true)
                if q.screen and q.screen.Parent then q.screen.Enabled=false end
                task.spawn(function()
                    local controllers=game:GetService("ReplicatedStorage"):FindFirstChild("Controllers")
                    local ui=controllers and controllers:FindFirstChild("UI")
                    local module=ui and ui:FindFirstChild("GiftWindow")
                    if not module or not module:IsA("ModuleScript")then return end
                    local loaded,controller=pcall(require,module)
                    if loaded and quote==q and active() and q.screen and q.screen.Parent and not q.screen.Enabled
                        and type(controller)=="table" and type(controller.Close)=="function"then
                        pcall(controller.Close,controller)
                    end
                end)
                message="Simulated gift: "..q.item.name.." → "..q.username..". Not delivered."
            else dismiss()end
            onChange(message)
        end
    end
    function binding:confirm()
        if not quote or not checkout or self.phase~="Confirm" or elapsed<2.5 then return false end
        if not validQuote()then
            dismiss();onChange("Selection or balance changed. Open Gift again.");return false
        end
        closeDialog();self.phase="Purchasing";elapsed=0
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
                    screen=frame:FindFirstAncestorWhichIsA("ScreenGui")}
                self.phase="Preparing";elapsed=0;return true
            end
        end
        onChange(message)
        return false,message
    end
    function binding:refresh()
        if active() and self.phase=="Completed"then return end
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
