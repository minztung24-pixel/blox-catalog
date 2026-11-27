local NativeAbilities={}

function NativeAbilities.supports(item)
    return item.category=="Skills"or item.category=="Permanent"
end

local function connect(player)
    assert(type(getloadedmodules)=="function"and type(hookfunction)=="function"
        and debug and type(debug.getupvalues)=="function"and type(getconnections)=="function",
        "Native ability UI needs cached modules and readable UI connections")
    local loaded={}
    for _,node in pairs(getloadedmodules())do loaded[node]=true end
    local storage=game:GetService("ReplicatedStorage")
    local function cached(node)
        assert(node and loaded[node],"Open Items and equip a real ability once, then Rescan")
        local result
        local worker=task.spawn(function()result=table.pack(pcall(require,node))end)
        local deadline=os.clock()+3
        while not result and os.clock()<deadline do task.wait(.03)end
        if not result then pcall(task.cancel,worker);error("Native ability module timed out")end
        assert(result[1],result[2]);return result[2]
    end
    local config=cached(storage:FindFirstChild("ItemConfig"))
    local service=cached(storage:FindFirstChild("ItemReplicationService"))
    local skills=cached(storage:FindFirstChild("FruitSkills"))
    local pg=player:FindFirstChildOfClass("PlayerGui")
    local main=pg and pg:FindFirstChild("Main")
    local ui=main and main:FindFirstChild("UIController")
    local setup=cached(ui and ui:FindFirstChild("SetUpSkills"))
    local target
    for _,value in pairs(debug.getupvalues(setup))do
        if type(value)=="function"and debug.info(value,"n")=="getToolData"then
            assert(not target,"Ambiguous native skill-data function");target=value
        end
    end
    assert(target,"Native skill-data function unavailable")
    local api={data=setmetatable({},{__mode="k"})}
    local original
    original=hookfunction(target,function(gui,tool)
        if not api.closed and api.data[tool]and tool:GetAttribute("BloxCatalogAbility")then return api.data[tool]end
        return original(gui,tool)
    end)
    assert(type(original)=="function","Native skill-data hook failed")
    local function rowFor(tool)
        local root=pg:FindFirstChild("Backpack")
        if not root then return nil end
        local count=0
        for _,node in ipairs(root:GetDescendants())do
            if node:IsA("GuiButton")then
                count+=1;if count>300 then break end
                for _,connection in ipairs(getconnections(node.Activated))do
                    if connection.Enabled~=false and type(connection.Function)=="function"then
                        for _,value in pairs(debug.getupvalues(connection.Function))do
                            if type(value)=="table"and type(value.Tools)=="table"and table.find(value.Tools,tool)
                                and typeof(value._Obj)=="Instance"and value._Obj:IsDescendantOf(root)
                                and type(value.Drag)=="function"and debug.info(value.Drag,"n")=="Drag"then return value end
                        end
                    end
                end
            end
        end
    end
    function api:slot(tool)
        local row=rowFor(tool);return row and row.Slot
    end
    function api:place(tool,slot)
        local deadline=os.clock()+2
        repeat
            local row=rowFor(tool)
            if row then
                if row.Slot~=slot then
                    -- Native Drag's numeric branch only swaps local hotbar rows; it does not invoke actions.
                    local guiService=game:GetService("GuiService")
                    local selected=guiService.SelectedObject
                    row:Drag(nil,slot)
                    if not selected or selected.Parent then guiService.SelectedObject=selected end
                end
                return row.Slot==slot
            end
            task.wait(.03)
        until self.closed or os.clock()>=deadline
        return false,"Native hotbar row unavailable"
    end
    function api:resolve(item)
        local moveset=config.tryGet(tonumber(item.id))
        if item.category=="Permanent"then
            moveset=config.Query.selectOne({Index={IdType="Moveset"},Moveset={SkillRedirect={Operation="EQ",Value=nil}},Economy={PurchaseWith=tonumber(item.id)}}):asNullable()
        end
        assert(moveset and moveset.Index.IdType=="Moveset","Native moveset metadata unavailable: "..item.name)
        local definition=moveset.Moveset
        local name=moveset.Index.StorageKey
        local tooltip=definition.Type=="Fruit"and "Blox Fruit"or definition.Type=="FightingStyle"and "Melee"
        assert(tooltip and skills[name]and skills[name][1],"Native skill list unavailable: "..name)
        local id=moveset.Index.ItemId
        local combat=service:ReadItem(service.KEYS.COMBAT_DATA,id,nil)
        assert(type(combat)=="table"and type(combat.Lvl)=="table"and type(combat.Cooldown)=="table"
            and type(combat.Cost)=="table"and type(combat.Cap)=="number","Native combat data unavailable: "..name)
        local mastery=service:ReadItem(service.KEYS.MASTERY,id,nil)or 1
        assert(type(mastery)=="number"and mastery>=1 and mastery<=600 and mastery%1==0,"Invalid native mastery")
        return {id=id,name=name,tooltip=tooltip,mastery=mastery,exp=0,combat=combat}
    end
    function api:close()
        if self.closed then return end
        self.closed=true;hookfunction(target,original);table.clear(self.data)
    end
    return api
end

function NativeAbilities.new(state,player,connector)
    local binding={slots={}}
    local api,stash
    function binding:remove(id)
        for slot,entry in pairs(self.slots)do if entry.id==id then
            self.slots[slot]=nil
            api.data[entry.tool]=nil;entry.tool:Destroy()
            local row=state.items[id]
            if row and row.tool==entry.tool then row.tool=nil;row.equipped=false;row.ability=nil end
            local backpack=player:FindFirstChildOfClass("Backpack")
            for _,saved in ipairs(entry.originals)do
                if saved.tool.Parent==stash then
                    saved.tool.Parent=backpack or saved.parent
                    if saved.slot and backpack then pcall(api.place,api,saved.tool,saved.slot)end
                end
            end
            return true
        end end
        return false
    end
    function binding:equip(item)
        local ok,message=pcall(function()
            assert(NativeAbilities.supports(item),"Item is not an ability preview")
            local row=state.items[item.id]
            assert(row and row.count>0,"Add the item first")
            local character=player.Character
            local humanoid=character and character:FindFirstChildOfClass("Humanoid")
            local backpack=player:FindFirstChildOfClass("Backpack")
            assert(humanoid and humanoid.Health>0 and backpack,"Wait for your character to spawn")
            if not api then api=(connector or connect)(player)end
            local metadata=api:resolve(item)
            local slot=item.category=="Permanent"and 2 or 1
            if self.slots[slot]then self:remove(self.slots[slot].id)end
            if not stash then stash=Instance.new("Folder");stash.Name="BloxCatalogAbilityStash";stash.Parent=player:FindFirstChildOfClass("PlayerGui")or backpack.Parent end
            local tool=Instance.new("Tool")
            tool.Name=metadata.name;tool.ToolTip=metadata.tooltip;tool.RequiresHandle=false
            tool.CanBeDropped=false;tool.Enabled=false;tool.ManualActivationOnly=true
            tool:SetAttribute("ItemId",metadata.id);tool:SetAttribute("BloxCatalogOwned",true);tool:SetAttribute("BloxCatalogAbility",true)
            tool:SetAttribute("Level",metadata.mastery);tool:SetAttribute("Exp",metadata.exp)
            local level=Instance.new("IntValue",tool);level.Name="Level";level.Value=metadata.mastery
            local exp=Instance.new("IntValue",tool);exp.Name="Exp";exp.Value=metadata.exp
            local entry={id=item.id,tool=tool,originals={}}
            self.slots[slot]=entry;api.data[tool]=metadata.combat;row.tool=tool;row.ability=true
            for _,root in ipairs({backpack,character})do for _,real in ipairs(root:GetChildren())do
                if real:IsA("Tool")and real.ToolTip==metadata.tooltip and not real:GetAttribute("BloxCatalogOwned")then
                    table.insert(entry.originals,{tool=real,parent=real.Parent,slot=api:slot(real)})
                    real.Parent=stash
                end
            end end
            tool.Parent=backpack
            local placed,why=api:place(tool,slot)
            assert(placed,why or "Native slot placement failed")
            humanoid:EquipTool(tool)
            assert(tool.Parent==character,"Ability preview did not equip")
            row.equipped=true
        end)
        if not ok then self:remove(item.id);return false,tostring(message)end
        return true,nil,"ability"
    end
    function binding:close(final)
        local ids={}
        for _,entry in pairs(self.slots)do table.insert(ids,entry.id)end
        for _,id in ipairs(ids)do self:remove(id)end
        if stash and #stash:GetChildren()==0 then stash:Destroy();stash=nil end
        if final and api then api:close();api=nil end
    end
    return binding
end
return NativeAbilities
