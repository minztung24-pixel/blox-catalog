return function(NativeEquip)
    local gui=Instance.new("Folder")
    local main=Instance.new("Folder",gui);main.Name="Main"
    local inventory=Instance.new("Frame",main);inventory.Name="InventoryContainer"
    local left=Instance.new("Frame",inventory);left.Name="Left"
    local label=Instance.new("TextLabel",left);label.Name="ItemName";label.Text="Arcsteel\nMagnet"
    local button=Instance.new("TextButton",left);button.Name="Equip";button.Size=UDim2.fromOffset(112,42);button.ZIndex=3
    local state={items={['1525']={item={id="1525",name="Arcsteel Magnet",category="Fruit Skins",isPhysicalFruit=true},count=1}},native={entries={[1525]={}}}}
    local binding=NativeEquip.new(gui,state,function()error("refresh must not invoke Equip")end)
    local ok,err=pcall(function()
        binding:refresh()
        local overlay=assert(left:FindFirstChild("BloxCatalogEquip"))
        assert(overlay.Size==button.Size and overlay.ZIndex>button.ZIndex and button.Visible)
        assert(overlay:GetAttribute("LocalSimulation"))
        state.native.entries[1525].original=1
        binding:refresh();assert(not left:FindFirstChild("BloxCatalogEquip"),"Real stock must retain the native callback")
        state.native.entries[1525].original=nil;label.Text="Other fruit"
        binding:refresh();assert(not left:FindFirstChild("BloxCatalogEquip"))
        label.Text="Arcsteel Magnet";binding:refresh();binding:close();binding:refresh()
        assert(not left:FindFirstChild("BloxCatalogEquip") and button.Visible,"Cleanup must leave the native button intact")
    end)
    binding:close();gui:Destroy();assert(ok,err)
    return "Legacy native Equip assertions passed"
end
