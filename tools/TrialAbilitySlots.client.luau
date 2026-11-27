-- Reversible local UI trial; no attacks, purchases or inventory actions.
local Abilities=loadstring(readfile("codex-native-abilities-test.lua"))()
local player=game:GetService("Players").LocalPlayer
local state={items={}}
local binding=Abilities.new(state,player)
local report={placeId=game.PlaceId,samples={},complete=false}
local function snapshot(item,ok,message)
    local row={item=item.name,ok=ok,error=message,texts={},hotbar={}}
    local main=player.PlayerGui:FindFirstChild("Main")
    local skills=main and main:FindFirstChild("Skills")
    if skills then for _,node in ipairs(skills:GetDescendants())do
        if node:IsA("TextLabel")and node.Visible and node.Text~=""then
            local visible=true;local parent=node.Parent
            while parent and parent~=skills do if parent:IsA("GuiObject")and not parent.Visible then visible=false;break end;parent=parent.Parent end
            if visible then table.insert(row.texts,{name=node.Name,text=node.Text})end
        end
    end end
    local backpack=player.PlayerGui:FindFirstChild("Backpack")
    local hotbar=backpack and backpack:FindFirstChild("Hotbar")
    local container=hotbar and hotbar:FindFirstChild("Container")
    if container then for _,node in ipairs(container:GetChildren())do if node:IsA("Frame")then
        local number=node:FindFirstChild("Number");local image=node:FindFirstChild("Image")
        table.insert(row.hotbar,{name=node.Name,slot=node.LayoutOrder,number=number and number.Text,image=image and image.Image})
    end end end
    local entry=state.items[item.id]
    row.proxy=entry and entry.tool and {name=entry.tool.Name,tooltip=entry.tool.ToolTip,handle=entry.tool.RequiresHandle,
        itemId=entry.tool:GetAttribute("ItemId"),held=entry.tool.Parent==player.Character}
    table.insert(report.samples,row)
end
local ran,errorMessage=pcall(function()
    for _,item in ipairs({{id="1184",name="Death Step",category="Skills"},{id="358",name="Permanent Control",category="Permanent"}})do
        state.items[item.id]={item=item,count=1}
        local ok,message=binding:equip(item)
        task.wait(1)
        snapshot(item,ok,message)
    end
end)
local closed,closeError=pcall(binding.close,binding,true)
report.complete=true;report.ran=ran;report.error=not ran and tostring(errorMessage)or nil
report.restored=closed;report.restoreError=not closed and tostring(closeError)or nil
if isfile("codex-native-items-test.lua")then
    local NativeItems=loadstring(readfile("codex-native-items-test.lua"))()
    local bridge
    local measured,why=pcall(function()
        local service=require(game.ReplicatedStorage.ItemReplicationService)
        local item={id="884",name="Dragon (West)",category="Fruits"}
        report.mastery={before=tostring(service:ReadItem(service.KEYS.MASTERY,884,nil))}
        bridge=NativeItems.connect(function()return true end)
        local ok,message=bridge:sync(item,1,false,false)
        assert(ok,message)
        report.mastery.after=tostring(service:ReadItem(service.KEYS.MASTERY,884,nil))
        assert(bridge:close());bridge=nil
        report.mastery.restored=tostring(service:ReadItem(service.KEYS.MASTERY,884,nil))
    end)
    if bridge then pcall(bridge.close,bridge)end
    report.masteryOk=measured;report.masteryError=not measured and tostring(why)or nil
end
local filename="blox-catalog-ability-trial-"..game.PlaceId..".json"
writefile(filename,game:GetService("HttpService"):JSONEncode(report))
print("Ability UI trial saved: "..filename)
return report
