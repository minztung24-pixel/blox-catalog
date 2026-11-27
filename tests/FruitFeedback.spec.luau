-- Client Play: take-out notices are emitted once, after successful local changes only.
return function(Equipment)
    local folder=Instance.new("Folder",workspace)
    local character=Instance.new("Model",folder)
    local head=Instance.new("Part",character);head.Name="Head";head.Anchored=true
    local humanoid=Instance.new("Humanoid",character);humanoid.RequiresNeck=false
    local root=Instance.new("Part",character);root.Name="HumanoidRootPart";root.Anchored=true
    local backpack=assert(game:GetService("Players").LocalPlayer):FindFirstChildOfClass("Backpack")
    local player={Character=character,FindFirstChildOfClass=function()return backpack end}
    local source=Instance.new("Tool",folder);Instance.new("Part",source).Name="Handle"
    local item={id="999010",name="Feedback fixture",category="Fruit Skins",isPhysicalFruit=true}
    local row={item=item,count=1}
    local deny,missing=false,false
    local notices={}
    local state={items={[item.id]=row},native={sync=function()return not deny,"fixture denied"end}}
    local controller=Equipment.new(state,player,function()if not missing then return source end end,function(message,native)
        if native then table.insert(notices,message)end
    end)
    local ok,reason=pcall(function()
        missing=true
        assert(not controller:equip(item)and #notices==0,"Missing model must not announce success")
        missing=false;deny=true
        assert(not controller:equip(item)and #notices==0,"Failed inventory sync must not announce success")
        deny=false
        assert(controller:equip(item)and #notices==1 and notices[1]=="Fruit added to backpack.")
        assert(controller:equip(item)and #notices==1,"Holding the same Tool again is not another take-out")
        deny=true
        assert(not controller:store(item)and #notices==1 and row.tool,"Failed Store preserves the Tool and shows no success")
        deny=false
        assert(controller:store(item)and #notices==2 and notices[2]=="Blox Fruit stored."and row.count==1)
        assert(not controller:store(item)and #notices==2,"Repeated Store cannot announce success twice")
        assert(controller:equip(item)and #notices==3 and notices[3]=="Fruit added to backpack.")
    end)
    controller:close(true);folder:Destroy()
    assert(ok,reason)
    return "Fruit feedback success, failure, repeated Equip and Store assertions passed"
end
