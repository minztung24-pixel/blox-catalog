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
    local ok,err=pcall(function()
        assert(not controller:store(item) and row.tool==tool and tool.Parent==character,"Failed stock sync must preserve held Tool")
        assert(controller:drop(item) and tool.Parent==workspace and not row.equipped)
        assert(tool.Handle.CanCollide and tool.Handle:FindFirstChild("BloxCatalogPickup"))
        assert((tool.Handle.Position-(humanoidRoot.CFrame*CFrame.new(0,0,-4)).Position).Magnitude<0.01)
        deny=false
        assert(controller:store(item) and row.tool==nil and row.count==2 and tool.Parent==nil)
        assert(not controller:drop(item) and not controller:store(item))
    end)
    controller:close();root:Destroy();if tool.Parent then tool:Destroy() end
    assert(ok,err)
    return "Local fruit action assertions passed"
end
