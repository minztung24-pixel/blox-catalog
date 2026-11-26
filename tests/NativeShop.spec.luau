return function(NativeShop,Inventory)
    local pg=Instance.new("Folder")
    local gui=Instance.new("ScreenGui",pg);gui.Name="GiftWindow"
    local window=Instance.new("Frame",gui);window.Name="Window"
    local footer=Instance.new("Frame",window);footer.Name="Footer"
    local context=Instance.new("TextLabel",footer);context.Name="Context"
    local content=Instance.new("Frame",window);content.Name="Content"
    local buttons=Instance.new("Frame",content);buttons.Name="Buttons"
    local purchase=Instance.new("TextButton",buttons);purchase.Name="Purchase"
    local price=Instance.new("TextLabel",purchase);price.Name="TextLabel"
    price.Text='<font color="#000000">\u{E002}</font>3500'
    local state=Inventory.new()
    local changes=0
    local binding=NativeShop.new(pg,state,function()changes+=1 end,function()return true end)
    local ok,err=pcall(function()
        context.Text="Gifting <Permanent Magnet}> "
        binding:refresh()
        assert(purchase.Visible and not buttons:FindFirstChild("BloxCatalogVisualPurchase"))
        assert(Inventory.setBalance(state,"10000"))
        binding:refresh()
        local overlay=assert(buttons:FindFirstChild("BloxCatalogVisualPurchase"))
        assert(context:FindFirstChild("BloxCatalogGiftStatus"),"Preview status must not enter the Window's native layout")
        assert(not purchase.Visible and not purchase.Interactable and overlay.Interactable)
        assert(not binding:buy() and #state.gifts==0,"Unselected recipient must never buy")
        context.Text="Gifting [Player_123] <Permanent Magnet}> "
        binding:refresh()
        assert(binding:buy() and state.balance.robux==6500 and state.gifts[1].id=="1517")
        assert(state.gifts[1].recipient=="Player_123" and state.gifts[1].cost==3500)
        assert(price.Text=='<font color="#000000">\u{E002}</font>3500',"Native quote remains untouched")
        state.balance.plusDiscount=true
        binding:refresh()
        assert(overlay.TextLabel.Text:find("3150",1,true))
        assert(binding:buy() and state.balance.robux==3350)
        assert(binding:buy() and state.balance.robux==200)
        assert(not binding:buy() and state.balance.robux==200 and #state.gifts==3)
        context.Text="Gifting [Other_User] <Unknown Product}> "
        binding:refresh()
        assert(not binding:buy() and not purchase.Visible,"Unrecognized products stay blocked during preview")
        context.Text="Gifting [Other_User] <Permanent Buddha}> "
        price.Text="Price unavailable"
        assert(not binding:buy(),"Never guess a native quote")
        Inventory.resetBalance(state);binding:refresh()
        assert(purchase.Visible and purchase.Interactable and not overlay.Parent)
        assert(not binding:buy(),"Reset disables local purchase handling")
        Inventory.setBalance(state,"10000");binding:refresh()
        binding:close()
        assert(purchase.Visible and purchase.Interactable and not buttons:FindFirstChild("BloxCatalogVisualPurchase"))
        binding:refresh();assert(not buttons:FindFirstChild("BloxCatalogVisualPurchase"))
        assert(changes>0)
    end)
    binding:close();pg:Destroy();assert(ok,err)
    return "Native shop assertions passed: observed context, quote, local charge, discount, blocked unknowns, reset and cleanup"
end
