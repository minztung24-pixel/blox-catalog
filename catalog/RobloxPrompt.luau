-- Presentation only. Reference components/theme versions are recorded in docs/DIAG.md.
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Gui=game:GetService("GuiService")
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
    local reducedMotion=Gui.ReducedMotionEnabled
    local previousSelection=Gui.SelectedObject
    local height=completed and 280 or (q.discountLabel and 344 or 264)
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
    local function robux(name,x,y,size)
        local icon=Instance.new("ImageLabel",panel)
        icon.Name=name;icon.Image="rbxasset://textures/ui/common/robux@3x.png"
        icon.Position=UDim2.fromOffset(x,y);icon.Size=UDim2.fromOffset(size,size)
        icon.BackgroundTransparency=1;icon.ZIndex=3
    end
    local title=bold(label("Title",completed and "Purchase completed" or "Buy item",20,16,270,28,25))
    title.TextColor3=Color3.fromRGB(213,215,221)
    local close=button("Close","×",408,10,36,36,function()self:cancel()end)
    close.BackgroundTransparency=1;close.TextSize=28
    if completed then
        local circle=Instance.new("Frame",panel)
        circle.Name="CheckCircle";circle.Position=UDim2.fromOffset(204,52);circle.Size=UDim2.fromOffset(48,48)
        circle.BackgroundTransparency=1;circle.ZIndex=3
        Instance.new("UICorner",circle).CornerRadius=UDim.new(1,0)
        local stroke=Instance.new("UIStroke",circle);stroke.Thickness=2;stroke.Color=Color3.fromRGB(220,222,228)
        local check=label("Check","✓",204,52,48,48,30);check.TextXAlignment=Enum.TextXAlignment.Center
        local result=label("Result",q.resultText,20,116,416,64,18)
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
        bold(label("Product",q.productName,108,60,328,32,18))
        robux("PriceIcon",108,101,16)
        local amount=bold(label("Price",number(q.cost),132,94,160,28,18))
        if q.cost~=q.price then
            local old=label("OriginalPrice","<s>"..number(q.price).."</s>",132,94,140,28,15)
            local function alignPrice()old.Position=UDim2.fromOffset(132+amount.TextBounds.X+16,94)end
            table.insert(connections,amount:GetPropertyChangedSignal("TextBounds"):Connect(alignPrice))
            alignPrice()
            old.RichText=true;old.TextColor3=Color3.fromRGB(213,215,221)
        end
        if q.discountLabel then
            local row=Instance.new("Frame",panel)
            row.Name="DiscountRow";row.Position=UDim2.fromOffset(20,154);row.Size=UDim2.fromOffset(416,56)
            row.BackgroundColor3=Color3.fromRGB(32,34,39);row.BorderSizePixel=0;row.ZIndex=2
            Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
            robux("DiscountIcon",36,173,18)
            bold(label("Discount",q.discountLabel,62,168,350,28,18))
        end
    end
    local primary=button(completed and "OK" or "Buy",completed and "OK" or "Buy",20,height-(completed and 80 or 110),416,40,function()
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
    local scope=label("Scope","SIMULATION · No real Robux spent or gift delivered.",20,height-45,416,24,13)
    scope.TextColor3=Color3.fromRGB(188,190,200);scope.TextXAlignment=Enum.TextXAlignment.Center
    table.insert(connections,Input.InputBegan:Connect(function(input)
        if input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.ButtonB then self:cancel()end
    end))

    gui:SetAttribute("Phase",completed and "Completed" or "Confirm")
    gui:SetAttribute("Renderer","LocalRobloxPrompt")
    gui:SetAttribute("ReducedMotion",reducedMotion)
    self.gui=gui
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
