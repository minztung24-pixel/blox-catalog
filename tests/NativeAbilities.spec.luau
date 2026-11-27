return function(Abilities)
    local root=Instance.new("Folder",workspace)
    local player=assert(game:GetService("Players").LocalPlayer,"Run the ability equip suite in a client playtest")
    local character=assert(player.Character)
    local backpack=player:FindFirstChildOfClass("Backpack")
    local state={items={}}
    local original=Instance.new("Tool",backpack);original.Name="Real melee";original.ToolTip="Melee";original.RequiresHandle=false
    local fruit=Instance.new("Tool",backpack);fruit.Name="Real fruit";fruit.ToolTip="Blox Fruit";fruit.RequiresHandle=false
    local calls,closed={},0
    local data={Lvl={Z=1},Cost={Z=10},Cooldown={Z=5},Cap=100}
    local api={data={}}
    function api:resolve(item)
        if item.id=="missing"then error("Native moveset data unavailable")end
        return {id=item.category=="Permanent"and 402 or tonumber(item.id),name=item.category=="Permanent"and "Control-Control"or item.name,
            tooltip=item.category=="Permanent"and "Blox Fruit"or "Melee",mastery=17,exp=0,combat=data}
    end
    function api:place(tool,slot)table.insert(calls,{tool=tool,slot=slot});return true end
    function api:slot(tool)return tool==original and 1 or tool==fruit and 2 or nil end
    function api:close()closed+=1 end
    local binding=Abilities.new(state,player,function()return api end)
    local first={id="1184",name="Death Step",category="Skills"}
    local second={id="1144",name="Dragon Breath",category="Skills"}
    local permanent={id="358",name="Permanent Control",category="Permanent"}
    for _,item in ipairs({first,second,permanent})do state.items[item.id]={item=item,count=1}end
    local ok,err=pcall(function()
        assert(binding:equip(first))
        local proxy=assert(state.items[first.id].tool)
        assert(proxy.RequiresHandle==false and not proxy:FindFirstChild("Handle"))
        assert(not proxy.Enabled and proxy.ManualActivationOnly and not proxy:FindFirstChildWhichIsA("LuaSourceContainer",true))
        assert(proxy:GetAttribute("ItemId")==1184 and proxy.Level.Value==17 and api.data[proxy]==data)
        assert(calls[#calls].slot==1 and original.Parent~=backpack and fruit.Parent==backpack)
        assert(binding:equip(second))
        assert(not proxy.Parent and state.items[first.id].tool==nil and calls[#calls].slot==1)
        assert(binding:equip(permanent))
        local fruitProxy=state.items[permanent.id].tool
        assert(fruitProxy.Name=="Control-Control"and fruitProxy:GetAttribute("ItemId")==402 and fruitProxy.ToolTip=="Blox Fruit")
        assert(calls[#calls].slot==2 and state.items[second.id].tool.Parent==backpack)
        assert(not binding:equip({id="missing",category="Skills"}),"Unsupported metadata cannot fabricate a moveset")
        assert(binding:remove(permanent.id)and fruit.Parent==backpack and not fruitProxy.Parent)
        binding:close(true)
        assert(original.Parent==backpack and original.Name=="Real melee"and original.Enabled and closed==1)
        assert(not state.items[second.id].tool and state.items[second.id].count==1)
    end)
    binding:close(true);original:Destroy();fruit:Destroy();root:Destroy();assert(ok,err)
    return "Native ability slot assertions passed"
end
