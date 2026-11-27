-- Presentation only. Reference components/theme versions are recorded in docs/DIAG.md.
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Gui=game:GetService("GuiService")
local iconFont=Font.new("rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json",Enum.FontWeight.Regular)
local RobloxPrompt={}
local function bezier(x,x1,y1,x2,y2)
    if x<=0 or x>=1 then return x end
    local function point(t,a,b)return 3*(1-t)*(1-t)*t*a+3*(1-t)*t*t*b+t*t*t end
    local low,high=0,1
    for _=1,18 do
        local t=(low+high)/2
        if point(t,x1,x2)<x then low=t else high=t end
    end
    return point((low+high)/2,y1,y2)
end
local function number(value)
    local formatted=string.format("%.0f",value)
    repeat
        local count
        formatted,count=formatted:gsub("^(%d+)(%d%d%d)","%1,%2")
        if count==0 then return formatted end
    until false
end
function RobloxPrompt.open(playerGui,data,completed,onBuy,onCancel)
    assert(type(data.productName)=="string" and type(data.resultText)=="string","Invalid prompt text")
    assert(type(onBuy)=="function" and type(onCancel)=="function","Missing prompt callbacks")
    for _,key in ipairs({"balance","price","cost"})do
        local n=data[key]
        assert(type(n)=="number" and n>=0 and n<=9007199254740991 and n%1==0,"Invalid prompt amount")
    end
    local q=data
    local self={}
    local age,closingAge,closingOffset,closingAlpha=0,nil,0,0
    local submitted,destroyed=false,false
    local connections={}
    local closeHeartbeat
    local discountParts={}
    local expanded=false
    local reducedMotion=Gui.ReducedMotionEnabled
    local previousSelection=Gui.SelectedObject
    local height=completed and 236 or (q.discountLabel and 344 or 264)
    local gui=Instance.new("ScreenGui")
    gui.Name="BloxCatalogCheckout";gui.ResetOnSpawn=false
    gui:SetAttribute("Simulation",true)
    gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
    gui.ScreenInsets=Enum.ScreenInsets.DeviceSafeInsets
    local order=0
    for _,child in ipairs(playerGui:GetChildren())do
        if child:IsA("ScreenGui")then order=math.max(order,child.DisplayOrder)end
    end
    gui.DisplayOrder=order+1
    local shade=Instance.new("TextButton",gui)
    shade.Name="Shade";shade.Size=UDim2.fromScale(1,1);shade.BackgroundColor3=Color3.fromRGB(10,10,14)
    shade.BackgroundTransparency=1;shade.Text="";shade.AutoButtonColor=false;shade.Modal=true
    local panel=Instance.new("CanvasGroup",shade)
    panel.Name="Dialog";panel.AnchorPoint=Vector2.new(.5,.5);panel.Position=UDim2.fromScale(.5,.5)
    panel.Size=UDim2.fromOffset(456,height);panel.BackgroundColor3=Color3.fromRGB(25,26,31)
    panel.BorderSizePixel=0;panel.ZIndex=2;panel.Active=true
    local corner=Instance.new("UICorner",panel);corner.CornerRadius=UDim.new(0,16)
    local stroke=Instance.new("UIStroke",panel)
    stroke.Color=Color3.fromRGB(208,217,251);stroke.Transparency=.88;stroke.Thickness=1
    local scale=Instance.new("UIScale",panel)
    local function fit()
        local camera=workspace.CurrentCamera
        local viewport=camera and camera.ViewportSize or Vector2.new(800,600)
        scale.Scale=math.min(1,math.max(1,viewport.X-24)/456,math.max(1,viewport.Y-100)/height)
    end
    fit()
    local camera=workspace.CurrentCamera
    if camera then table.insert(connections,camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))end
    local function label(name,text,x,y,w,h,size)
        local node=Instance.new("TextLabel",panel)
        node.Name=name;node.Text=text;node.Position=UDim2.fromOffset(x,y);node.Size=UDim2.fromOffset(w,h)
        node.BackgroundTransparency=1;node.TextColor3=Color3.fromRGB(213,215,221)
        node.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json");node.TextSize=size or 18
        node.TextXAlignment=Enum.TextXAlignment.Left;node.TextWrapped=true;node.ZIndex=3
        return node
    end
    local function button(name,text,x,y,w,h,callback)
        local node=Instance.new("TextButton",panel)
        node.Name=name;node.Text=text;node.Position=UDim2.fromOffset(x,y);node.Size=UDim2.fromOffset(w,h)
        node.BackgroundColor3=Color3.fromRGB(51,95,255);node.TextColor3=Color3.fromRGB(247,247,248)
        node.TextSize=18;node.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json",Enum.FontWeight.Medium)
        node.BorderSizePixel=0;node.ZIndex=4
        Instance.new("UICorner",node).CornerRadius=UDim.new(0,8)
        table.insert(connections,node.Activated:Connect(callback))
        return node
    end
    local function bold(node)
        node.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json",Enum.FontWeight.Bold)
        node.TextColor3=Color3.fromRGB(247,247,248)
        return node
    end
    local function symbol(name,glyph,x,y,size)
        local icon=label(name,glyph,x,y,size,size,size)
        icon.FontFace=iconFont;icon.TextWrapped=false;icon.AutoLocalize=false
        icon.TextXAlignment=Enum.TextXAlignment.Center
        return icon
    end
    local function robux(name,x,y,size)return symbol(name,"robux",x,y,size)end
    local title=bold(label("Title",completed and "Purchase completed" or "Buy item",20,16,270,28,25))
    title.TextColor3=Color3.fromRGB(213,215,221)
    local close=button("Close","",404,8,40,40,function()self:cancel()end)
    close.BackgroundTransparency=1
    local closeIcon=symbol("Icon","x",8,8,24)
    closeIcon.Parent=close;closeIcon.ZIndex=5
    local mode=label("SimulationMode","LOCAL SIMULATION",20,42,180,14,12)
    mode.TextColor3=Color3.fromRGB(255,208,110)
    if completed then
        symbol("Check","circle-check",204,64,48)
        local result=label("Result",q.resultText,20,124,416,32,18)
        result.TextXAlignment=Enum.TextXAlignment.Center
    else
        robux("BalanceIcon",308,21,18)
        local balance=bold(label("Balance",number(q.balance),304,16,94,28,18))
        balance.FontFace=Font.new("rbxasset://fonts/families/BuilderSans.json",Enum.FontWeight.Medium)
        balance.TextXAlignment=Enum.TextXAlignment.Right
        local function alignBalance()
            panel.BalanceIcon.Position=UDim2.fromOffset(398-balance.TextBounds.X-24,21)
        end
        table.insert(connections,balance:GetPropertyChangedSignal("TextBounds"):Connect(alignBalance))
        alignBalance()
        local icon=Instance.new("ImageLabel",panel)
        icon.Name="Icon";icon.Image=q.icon;icon.BackgroundTransparency=1
        icon.Position=UDim2.fromOffset(20,58);icon.Size=UDim2.fromOffset(72,72);icon.ZIndex=3
        if q.iconRectOffset then icon.ImageRectOffset=Vector2.new(table.unpack(q.iconRectOffset))end
        if q.iconRectSize then icon.ImageRectSize=Vector2.new(table.unpack(q.iconRectSize))end
        bold(label("Product",q.productName,100,64,336,32,18))
        robux("PriceIcon",100,97,18)
        local amount=bold(label("Price",number(q.cost),123,92,160,28,18))
        if q.cost~=q.price then
            local old=label("OriginalPrice","<s>"..number(q.price).."</s>",123,92,140,28,15)
            local function alignPrice()old.Position=UDim2.fromOffset(123+amount.TextBounds.X+8,92)end
            table.insert(connections,amount:GetPropertyChangedSignal("TextBounds"):Connect(alignPrice))
            alignPrice()
            old.RichText=true;old.TextColor3=Color3.fromRGB(213,215,221)
        end
        if q.discountLabel then
            local row=Instance.new("Frame",panel)
            row.Name="DiscountRow";row.Position=UDim2.fromOffset(20,154);row.Size=UDim2.fromOffset(416,56)
            row.BackgroundColor3=Color3.fromRGB(32,34,39);row.BorderSizePixel=0;row.ZIndex=2
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
            symbol("DiscountIcon","roblox-plus",36,173,18)
            bold(label("Discount",q.discountLabel,62,168,326,28,18))
            local toggle=button("DiscountToggle","",0,0,416,56,function()self:toggleDiscount()end)
            toggle.Parent=row;toggle.BackgroundTransparency=1;toggle.ZIndex=4
            local arrow=label("DiscountArrow","chevron-small-down",390,168,32,28,16)
            arrow.FontFace=iconFont;arrow.TextWrapped=false;arrow.AutoLocalize=false
            arrow.TextXAlignment=Enum.TextXAlignment.Center
            local function detail(name,text,x,y,w,strong)
                local node=label(name,text,x,y,w,24,strong and 18 or 15)
                if strong then bold(node)end
                node.Visible=false;table.insert(discountParts,node)
                return node
            end
            local function detailAmount(name,value,y,strong)
                local node=detail(name,value,252,y,168,strong)
                node.TextXAlignment=Enum.TextXAlignment.Right
                robux(name.."Icon",0,y+5,14)
                local image=panel[name.."Icon"];image.Visible=false;table.insert(discountParts,image)
                local function align()image.Position=UDim2.fromOffset(420-node.TextBounds.X-20,y+5)end
                table.insert(connections,node:GetPropertyChangedSignal("TextBounds"):Connect(align));align()
            end
            detail("DiscountSubtotal","Subtotal",36,216,200)
            detailAmount("DiscountSubtotalAmount",number(q.price),216)
            detail("DiscountSavings","Roblox Plus",36,244,200)
            detailAmount("DiscountSavingsAmount","- "..number(q.price-q.cost),244)
            local line=Instance.new("Frame",panel)
            line.Name="DiscountDivider";line.Position=UDim2.fromOffset(36,276);line.Size=UDim2.fromOffset(384,1)
            line.BackgroundColor3=Color3.fromRGB(87,89,98);line.BorderSizePixel=0;line.ZIndex=3
            line.Visible=false;table.insert(discountParts,line)
            detail("DiscountTotal","Total",36,288,200,true)
            detailAmount("DiscountTotalAmount",number(q.cost),288,true)
        end
    end
    local primary=button(completed and "OK" or "Buy",completed and "OK" or "Buy",20,height-(completed and 60 or 86),416,40,function()
        self:activate()
    end)
    if not completed then
        local caption=Instance.new("TextLabel",primary)
        caption.Name="Caption";caption.Text=primary.Text;primary.Text=""
        caption.Size=UDim2.fromScale(1,1);caption.BackgroundTransparency=1
        caption.FontFace=primary.FontFace;caption.TextSize=primary.TextSize
        caption.TextColor3=primary.TextColor3;caption.ZIndex=primary.ZIndex+1
        local delay=Instance.new("UIGradient",primary);delay.Name="InputDelay"
        delay.Transparency=NumberSequence.new(.5)
        gui:SetAttribute("BuyReady",false);gui:SetAttribute("BuyProgress",0)
    end
    primary.Interactable=false;primary.AutoButtonColor=false;primary.Selectable=false
    local terms
    if not completed then
        terms=label("Terms","Your payment method will be charged. Roblox <u>Terms of Use</u> apply.",20,height-39,416,24,13)
        terms.RichText=true;terms.TextColor3=Color3.fromRGB(188,190,200)
        terms.TextXAlignment=Enum.TextXAlignment.Center
    end
    table.insert(connections,Input.InputBegan:Connect(function(input)
        if input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB then self:cancel()end
    end))

    gui:SetAttribute("Phase",completed and "Completed" or "Confirm")
    gui:SetAttribute("Renderer","LocalRobloxPrompt")
    gui:SetAttribute("ReducedMotion",reducedMotion)
    self.gui=gui
    gui:SetAttribute("DiscountExpanded",false)
    function self:toggleDiscount()
        if completed or not q.discountLabel or submitted or destroyed or closingAge~=nil then return false end
        expanded=not expanded;gui:SetAttribute("DiscountExpanded",expanded)
        height=expanded and 456 or 344
        panel.Size=UDim2.fromOffset(456,height)
        panel.DiscountRow.Size=UDim2.fromOffset(416,expanded and 168 or 56)
        panel.DiscountArrow.Text=expanded and "chevron-small-up"or "chevron-small-down"
        for _,node in ipairs(discountParts)do node.Visible=expanded end
        primary.Position=UDim2.fromOffset(20,height-86)
        terms.Position=UDim2.fromOffset(20,height-39)
        fit()
        return true
    end
    local function destroy(external)
        if destroyed then return end
        destroyed=true
        if closeHeartbeat then closeHeartbeat:Disconnect();closeHeartbeat=nil end
        for _,connection in ipairs(connections)do connection:Disconnect()end
        table.clear(connections)
        if Gui.SelectedObject and Gui.SelectedObject:IsDescendantOf(gui)then
            Gui.SelectedObject=previousSelection and previousSelection.Parent and previousSelection or nil
        end
        if not external then gui:Destroy()end
    end
    table.insert(connections,gui.Destroying:Connect(function()destroy(true)end))
    function self:ready()
        return not destroyed and closingAge==nil
            and age+1e-8>=(completed and .3 or 2.8)
    end
    function self:activate()
        if submitted or not self:ready()then return false end
        submitted=true
        primary.Interactable=false
        if completed then onCancel()else onBuy()end
        return true
    end
    function self:cancel()
        if destroyed or closingAge~=nil or submitted then return false end
        submitted=true;onCancel();return true
    end
    function self:step(dt)
        if destroyed or type(dt)~="number" or dt<0 or dt~=dt or dt==math.huge then return end
        if closingAge~=nil then
            closingAge+=dt
            local p=bezier(math.clamp(closingAge/.1,0,1),.8,0,.4,1)
            local offset=closingOffset+(32-closingOffset)*p
            panel.Position=UDim2.new(.5,0,.5,offset)
            panel.GroupTransparency=closingAlpha+(1-closingAlpha)*p
            shade.BackgroundTransparency=.25+.75*math.clamp(closingAge/.1,0,1)
            if closingAge>=.1 then destroy()end
            return
        end
        local previousAge=age
        age=math.min(age+dt,completed and .3 or 2.8)
        if age==previousAge and age>0 then return end
        local p=reducedMotion and 1 or bezier(math.clamp(age/.3,0,1),.2,0,0,1)
        panel.Position=UDim2.new(.5,0,.5,32*(1-p))
        panel.GroupTransparency=1-p
        shade.BackgroundTransparency=reducedMotion and .25 or 1-.75*math.clamp(age/.1,0,1)
        local ready=self:ready()and not submitted
        primary.Interactable=ready;primary.AutoButtonColor=ready;primary.Selectable=ready
        if not completed then
            local fraction=math.clamp((age-.3)/2.5,0,1)
            local progress=ready and 1 or fraction*fraction
            gui:SetAttribute("BuyProgress",progress);gui:SetAttribute("BuyReady",ready)
            primary.InputDelay.Transparency=progress>=1 and NumberSequence.new(0)or NumberSequence.new({
                NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(math.max(0,progress-.0001),0),
                NumberSequenceKeypoint.new(math.min(1,progress+.0001),.5),NumberSequenceKeypoint.new(1,.5)})
        end
        if ready and Input.PreferredInput==Enum.PreferredInput.Gamepad and Gui.SelectedObject==nil then
            Gui.SelectedObject=primary
        end
    end
    function self:close(animated)
        if destroyed then return end
        if not animated or reducedMotion then destroy();return end
        if closingAge~=nil then return end
        gui.Name=gui.Name.."Closing";gui:SetAttribute("Phase","Closing")
        closingAge=0;closingOffset=panel.Position.Y.Offset;closingAlpha=panel.GroupTransparency
        primary.Interactable=false;close.Interactable=false
        if Run:IsRunning() and Run:IsClient()then closeHeartbeat=Run.Heartbeat:Connect(function(dt)self:step(dt)end)end
    end
    table.insert(connections,shade.Activated:Connect(function()self:cancel()end))
    self:step(0)
    gui.Parent=playerGui
    return self
end
return RobloxPrompt
