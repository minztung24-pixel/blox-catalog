return function(Equipment)
    local player=game:GetService("Players").LocalPlayer
    local backpack=player:WaitForChild("Backpack")
    local state={items={}}
    local deny=false
    state.native={sync=function()return not deny,"Fixture denied"end}
    local controller=Equipment.new(state,player,function()return nil,"No source model"end,function()end)
    local ok,message=pcall(function()
        for _,entry in ipairs({{"1428","Celestial"},{"1429","Oni"}})do
            local item={id=entry[1],name=entry[2],category="Fruits",isPhysicalFruit=true}
            state.items[item.id]={item=item,count=1}
            local success,why,mode=controller:equip(item)
            assert(success,why)
            local tool=state.items[item.id].tool
            assert(mode=="hotbar"and tool.Parent==backpack and not state.items[item.id].equipped)
            assert(tool.Name==item.name and tool:GetAttribute("ItemId")==tonumber(item.id))
            assert(tool:GetAttribute("BloxCatalogHotbarOnly")and tool:GetAttribute("BloxCatalogOwned"))
            assert(not tool.RequiresHandle and not tool.Enabled and tool.ManualActivationOnly and not tool.CanBeDropped)
            assert(not tool:FindFirstChildWhichIsA("BasePart",true)and not tool:FindFirstChildWhichIsA("LuaSourceContainer",true),"Metadata Tools contain no invented mesh or code")
            assert(not controller:drop(item)and not controller.animations[item.id],"No physical Drop or animation for a metadata-only Tool")
            assert(controller:equip(item)and state.items[item.id].tool==tool,"Repeated request reuses the hotbar entry")
            controller:remove(item.id)
            assert(not tool.Parent and not state.items[item.id].tool)
            deny=true
            assert(not controller:equip(item)and not state.items[item.id].tool,"Failed stock sync must not leave a hotbar entry")
            deny=false
        end
        local item={id="1410",name="Venom",category="Fruits"}
        state.items[item.id]={item=item,count=1}
        assert(not controller:equip(item)and not state.items[item.id].tool,"Do not extend the exception to other missing models")
    end)
    controller:close(true)
    assert(ok,message)
    return "Celestial/Oni hotbar-only assertions passed"
end
