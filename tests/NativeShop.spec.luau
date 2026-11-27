return function(NativeShop,Inventory)
    local pg=Instance.new("Folder")
    local gui=Instance.new("ScreenGui",pg);gui.Name="GiftWindow"
    local window=Instance.new("Frame",gui);window.Name="Window"
    local footer=Instance.new("Frame",window);footer.Name="Footer"
    local context=Instance.new("TextLabel",footer);context.Name="Context"
    local content=Instance.new("Frame",window);content.Name="Content"
    local buttons=Instance.new("Frame",content);buttons.Name="Buttons"
    local purchase=Instance.new("TextButton",buttons);purchase.Name="Purchase"
    local cancel=Instance.new("TextButton",buttons);cancel.Name="Cancel"
    local price=Instance.new("TextLabel",purchase);price.Name="TextLabel"
    price.Text='<font color="#000000">\u{E002}</font>3500'
    local processing=Instance.new("Frame",window);processing.Name="Overlay";processing.Visible=false
    local loading=Instance.new("Frame",processing);loading.Name="Loading"
    local loadingImage=Instance.new("ImageLabel",loading);loadingImage.Name="ImageLabel";loadingImage.Image="rbxassetid://1"
    local loadingText=Instance.new("TextLabel",loading);loadingText.Name="TextLabel";loadingText.Text="Original caption"
    local state=Inventory.new()
    local changes=0
    local notices={}
    local nativeCloses=0
    local moduleEnv=getfenv(NativeShop.new)
    local savedGetConnections=rawget(moduleEnv,"getconnections")
    moduleEnv.getconnections=function(signal)
        assert(signal==cancel.Activated,"Only the verified native Cancel action may be invoked")
        return {{Enabled=true,Function=function()nativeCloses+=1;gui.Enabled=false end}}
    end
    local enabled=true
    local binding=NativeShop.new(pg,state,function(_,notice)changes+=1;if notice then table.insert(notices,notice)end end,function()return enabled end)
    local function buy()
        if binding.phase=="Idle"then gui.Enabled=true;binding:refresh()end
        local ok=binding:buy()
        if ok then binding:step(.33);binding:step(2.8)end
        return ok
    end
    local function confirm()
        local ok=binding:confirm()
        if ok then binding:step(.33)end
        return ok
    end
    local ok,err=pcall(function()
        context.Text="Gifting <Permanent Magnet}> "
        binding:refresh()
        assert(purchase.Visible and not buttons:FindFirstChild("BloxCatalogVisualPurchase"))
        assert(Inventory.setBalance(state,"10000"))
        binding:refresh()
        local overlay=assert(buttons:FindFirstChild("BloxCatalogVisualPurchase"))
        assert(not context:FindFirstChild("BloxCatalogGiftStatus"),"Gift window must not gain an extra preview banner")
        assert(overlay.TextLabel.Text==price.Text,"Gift price must keep the native label unchanged")
        assert(not purchase.Visible and not purchase.Interactable and overlay.Interactable)
        assert(not binding:buy() and #state.gifts==0,"Unselected recipient must never buy")
        context.Text="Gifting [Player_123] <Permanent Magnet}> "
        binding:refresh()
        assert(binding:buy() and state.balance.robux==10000 and #state.gifts==0,"Opening confirmation must not spend")
        assert(binding.phase=="Preparing" and processing.Visible,"Gift must show its existing processing overlay first")
        assert(not pg:FindFirstChild("BloxCatalogCheckout") and not binding:confirm())
        binding:step(.33)
        assert(pg.BloxCatalogCheckout:GetAttribute("Phase")=="Confirm")
        assert(pg.BloxCatalogCheckout.Shade.Dialog.Product.Text=="Magnet","Only the confirmation name is shortened")
        assert(pg.BloxCatalogCheckout.Shade.Dialog.Price.Text=="3,500","Use the game's current quote")
        assert(not pg.BloxCatalogCheckout:GetAttribute("BuyReady") and not binding:confirm(),"Early Buy must be blocked")
        pg.BloxCatalogCheckout:SetAttribute("BuyReady",true)
        assert(not binding:confirm(),"Readiness is checked against elapsed time, not a UI attribute")
        pg.BloxCatalogCheckout:SetAttribute("BuyReady",false)
        binding:step(.3)
        assert(pg.BloxCatalogCheckout:GetAttribute("BuyProgress")==0,"Roblox's initial input lock precedes the Buy fill")
        binding:step(1.25)
        assert(math.abs(pg.BloxCatalogCheckout:GetAttribute("BuyProgress")-.25)<.0001,"Native Otter Quad is ease-in, not ease-out")
        assert(not binding:confirm() and state.balance.robux==10000,"A partially filled button cannot charge")
        binding:step(1.25)
        assert(pg.BloxCatalogCheckout:GetAttribute("BuyReady") and state.balance.robux==10000)
        binding:cancel()
        assert(not pg:FindFirstChild("BloxCatalogCheckout") and state.balance.robux==10000)
        assert(not binding:confirm(),"Cancelled confirmation cannot charge")
        assert(not processing.Visible and loadingText.Text=="Original caption" and loadingImage.Image=="rbxassetid://1")
        assert(#notices==0,"Opening or cancelling cannot announce a gift")
        local nativePriceLabel=price.Text
        for _,entry in ipairs({{"Blade","100"},{"Flame","550"}})do
            context.Text="Gifting [Player_123] <Permanent "..entry[1].."}> "
            price.Text=entry[2]
            assert(buy())
            assert(pg.BloxCatalogCheckout.Shade.Dialog.Product.Text==entry[1])
            assert(pg.BloxCatalogCheckout.Shade.Dialog.Price.Text==entry[2])
            assert(pg.BloxCatalogCheckout.Shade.Dialog.PriceSummary.TotalAmount.Text==entry[2])
            binding:cancel()
        end
        assert(state.balance.robux==10000 and #state.gifts==0 and #notices==0)
        context.Text="Gifting [Player_123] <Permanent Magnet}> ";price.Text=nativePriceLabel
        assert(buy())
        assert(binding:confirm() and binding.phase=="Purchasing" and state.balance.robux==10000 and #state.gifts==0)
        assert(#notices==0,"Wait until completion is dismissed so the modal cannot dim or hide notices")
        assert(not binding:confirm() and not binding:buy(),"Repeated input while processing cannot buy")
        binding:step(.33)
        assert(state.balance.robux==6500 and state.gifts[1].id=="1517")
        assert(#notices==0,"Completion must retain the pending notifications")
        assert(nativeCloses==1,"Close through native Cancel so the shop's onClose callback is released")
        assert(not gui.Enabled and not processing.Visible,"Completed gift closes its original window")
        binding:refresh();assert(pg:FindFirstChild("BloxCatalogCheckout"),"Success remains visible after Gift closes")
        assert(pg.BloxCatalogCheckout:GetAttribute("Phase")=="Completed")
        assert(not binding:confirm() and not binding:buy() and state.balance.robux==6500,"Duplicate clicks cannot charge")
        assert(state.gifts[1].recipient=="Player_123" and state.gifts[1].cost==3500)
        assert(state.gifts[1].name=="Permanent Magnet","Presentation cannot rename the recorded item")
        gui.Enabled=true;context.Text="Gifting [Player_123] <Permanent Buddha}> "
        binding:refresh()
        assert(binding.phase=="Idle" and not pg:FindFirstChild("BloxCatalogCheckout"),"Opening another gift replaces the old completion")
        binding:step(.1)
        assert(#notices==1 and notices[1]=="<Color=White>Sending gift to Player_123...<Color=/>")
        binding:step(.22)
        assert(#notices==2 and notices[2]=="<Color=White>Gift sent successfully<Color=/>")
        binding:step(1);assert(#notices==2,"Completion notifications are emitted once")
        assert(binding:buy(),"A different fruit must work without reopening Shop")
        binding:cancel()
        context.Text="Gifting [Player_123] <Permanent Magnet}> "
        assert(price.Text=='<font color="#000000">\u{E002}</font>3500',"Native quote remains untouched")
        state.balance.plusDiscount=true
        binding:refresh()
        assert(overlay.TextLabel.Text==price.Text,"Visual discount belongs in checkout, not the original Gift price")
        assert(buy() and confirm() and state.balance.robux==3350)
        binding:cancel()
        assert(buy() and confirm() and state.balance.robux==200)
        binding:cancel()
        assert(not buy() and state.balance.robux==200 and #state.gifts==3)
        context.Text="Gifting [Other_User] <Unknown Product}> "
        binding:refresh()
        assert(not binding:buy() and not purchase.Visible,"Unrecognized products stay blocked during preview")
        context.Text="Gifting [Other_User] <Permanent Buddha}> "
        price.Text="Price unavailable"
        assert(not binding:buy(),"Never guess a native quote")
        price.Text="3500"
        Inventory.setBalance(state,"10000")
        assert(buy())
        context.Text="Gifting [Changed_User] <Permanent Buddha}> "
        assert(not binding:confirm() and state.balance.robux==10000,"Recipient change invalidates confirmation")
        assert(buy())
        price.Text="3600"
        binding:refresh()
        assert(not pg:FindFirstChild("BloxCatalogCheckout") and not binding:confirm(),"Quote change cancels pending purchase")
        assert(buy())
        state.balance.plusDiscount=false
        assert(not binding:confirm() and state.balance.robux==10000,"Discount change cannot alter a quoted charge")
        assert(buy())
        Inventory.resetBalance(state)
        Inventory.setBalance(state,"10000")
        assert(not binding:confirm(),"Reset and reapply invalidates the old session")
        assert(buy())
        enabled=false;binding:refresh()
        assert(purchase.Visible and not pg:FindFirstChild("BloxCatalogCheckout") and not binding:confirm())
        enabled=true;binding:refresh()
        assert(buy())
        gui.Enabled=false;binding:refresh()
        assert(not pg:FindFirstChild("BloxCatalogCheckout") and not purchase.Visible,"Closing Gift must keep its real purchase blocked until Reset")
        gui.Enabled=true;binding:refresh()
        assert(buy())
        Inventory.resetBalance(state);binding:refresh()
        assert(purchase.Visible and purchase.Interactable and not overlay.Parent)
        assert(not binding:buy(),"Reset disables local purchase handling")
        Inventory.setBalance(state,"10000");binding:refresh()
        assert(binding:buy() and binding.phase=="Preparing")
        Inventory.resetBalance(state);binding:refresh();binding:step(5)
        assert(state.balance.robux==0 and not processing.Visible and #state.gifts==3,"Reset cancels preparation")
        Inventory.setBalance(state,"10000");binding:refresh()
        assert(buy() and binding:confirm())
        Inventory.resetBalance(state);binding:refresh();binding:step(5)
        assert(state.balance.robux==0 and not processing.Visible and #state.gifts==3,"Reset cancels pending charge")
        Inventory.setBalance(state,"10000");binding:refresh()
        processing.Name="Unavailable"
        assert(not buy() and state.balance.robux==10000,"Missing native processing UI must not be invented")
        processing.Name="Overlay";processing.Visible=true
        assert(not buy(),"Never replace an already active native operation")
        processing.Visible=false
        assert(buy() and binding:confirm())
        binding:close()
        local noticesAtClose=#notices
        binding:step(5)
        assert(#notices==noticesAtClose,"Closed adapters cannot emit delayed notifications")
        assert(state.balance.robux==10000 and not processing.Visible,"Closed pending checkout cannot charge later")
        assert(not pg:FindFirstChild("BloxCatalogCheckout") and not binding:confirm())
        assert(purchase.Visible and purchase.Interactable and not buttons:FindFirstChild("BloxCatalogVisualPurchase"))
        binding:refresh();assert(not buttons:FindFirstChild("BloxCatalogVisualPurchase"))
        assert(changes>0)
    end)
    binding:close();pg:Destroy();moduleEnv.getconnections=savedGetConnections;assert(ok,err)
    return "Native shop assertions passed: native processing, timed Buy guard, delayed single charge, Gift closure, stale selection, cancel/reset and cleanup"
end
