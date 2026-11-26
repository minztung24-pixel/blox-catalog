return function(Equipment)
    local root=Instance.new("Folder",workspace)
    local character=Instance.new("Model",root)
    local humanoidRoot=Instance.new("Part",character);humanoidRoot.Name="HumanoidRootPart";humanoidRoot.CFrame=CFrame.new(0,10,0)
    local source=Instance.new("Tool",root);Instance.new("Part",source).Name="Handle"
    local item={id="1525",name="Arcsteel Magnet",category="Fruits"}
    local tool=assert(Equipment.clone(source,item));tool.Parent=character
    local row={item=item,count=2,tool=tool,equipped=true}
    local deny=true
    local state={items={[item.id]=row},native={sync=function(_,actual,count,outside)
        assert(actual==item and count==2 and not outside)
        return not deny,"fixture denied"
    end}}
    local player={Character=character}
    local controller=Equipment.new(state,player,function()end,function()end)
    local hand=Instance.new("Part",character);hand.Name="RightHand"
    local grip=Instance.new("Weld",hand);grip.Name="RightGrip";grip.Part0=hand;grip.Part1=tool.Handle
    local internal=Instance.new("Part",tool);internal.Transparency=1
    local weld=Instance.new("Weld",tool.Handle);weld.Part0=tool.Handle;weld.Part1=internal
    local ok,err=pcall(function()
        assert(not controller:store(item) and row.tool==tool and tool.Parent==character,"Failed stock sync must preserve held Tool")
        assert(controller:drop(item) and tool.Parent==workspace and not row.equipped)
        assert(grip.Parent==nil and weld.Parent==tool.Handle,"Release the hand, preserve internal model joints")
        assert(tool.Handle.CanCollide and tool.Handle.CanTouch and not tool.Handle.Massless)
        assert(not tool.Handle:FindFirstChild("BloxCatalogPickup"),"Dropped fruit has no custom pickup prompt")
        assert((tool.Handle.Position-(humanoidRoot.CFrame*CFrame.new(0,0,-5)).Position).Magnitude<0.01)
        assert((tool.Handle.AssemblyLinearVelocity-Vector3.new(0,1,0)).Magnitude<0.01)
        assert(tool.Handle.AssemblyAngularVelocity.Magnitude<0.01)
        assert(controller.dropBindings[item.id] and controller.dropBindings[item.id].Connected)
        local pickupConnection=controller.dropBindings[item.id]
        deny=false
        assert(controller:store(item) and row.tool==nil and row.count==2 and tool.Parent==nil)
        assert(not pickupConnection.Connected,"Store removes the pickup listener")
        assert(not controller:drop(item) and not controller:store(item))
    end)
    controller:close();root:Destroy();if tool.Parent then tool:Destroy() end
    assert(ok,err)
    return "Local fruit action assertions passed"
end
