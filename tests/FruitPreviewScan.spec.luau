return function(UI)
    local gui=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    assert(not gui:FindFirstChild("BloxCatalogSim") and not gui:FindFirstChild("__ReplicatedSpinnerInstances"),"Use an isolated Studio session")
    local holder=Instance.new("Folder",gui);holder.Name="__ReplicatedSpinnerInstances"
    local model=Instance.new("Model",holder);model.Name="Magnet-Magnet [PhysicalMoveset-1516]"
    model:SetAttribute("ItemId",1516);Instance.new("Part",model).Name="Handle"
    local unrelated=Instance.new("Tool",holder);unrelated.Name="Venom Fruit"
    Instance.new("Part",unrelated).Name="Handle"
    local active=Instance.new("Tool",workspace);active.Name="Portal-Portal [PhysicalMoveset-1414]"
    active:SetAttribute("ItemId",1414)
    local part=Instance.new("Part",active);part.Name="Handle";part.Anchored=true;part.CanTouch=false
    local catalog,lateHolder,lateTool
    local function waitFor(check)
        local deadline=os.clock()+2
        repeat task.wait(.02)until check()or os.clock()>deadline
        assert(check(),"Late native source did not update the Catalog card")
    end
    local ok,message=pcall(function()
        catalog=UI.start()
        local deadline=os.clock()+10
        repeat task.wait(.05) until catalog.Panel.Status.Text:find("models available",1,true) or os.clock()>deadline
        catalog.Panel.Search.Text="1516";task.wait()
        local card=assert(catalog.Panel.Items:FindFirstChild("Item_1516"))
        assert(card.BackgroundColor3==Color3.fromRGB(25,54,43),"Rescan must recognize the native preview source")
        catalog.Panel.Search.Text="1410";task.wait()
        card=assert(catalog.Panel.Items:FindFirstChild("Item_1410"))
        assert(card.BackgroundColor3==Color3.fromRGB(34,37,49),"Preview names without ItemId must not advertise a model")
        holder:Destroy()
        catalog.Panel.Search.Text="1516";task.wait()
        card=assert(catalog.Panel.Items:FindFirstChild("Item_1516"))
        assert(card.BackgroundColor3==Color3.fromRGB(25,54,43),"Keep the clean model available after native preview cleanup")
        active:Destroy()
        catalog.Panel.Search.Text="1414";task.wait()
        card=assert(catalog.Panel.Items:FindFirstChild("Item_1414"))
        assert(card.BackgroundColor3==Color3.fromRGB(25,54,43),"Cache a native preview Tool moved into Workspace before its display closes")
        catalog.Panel.Search.Text="1410";task.wait()
        lateHolder=Instance.new("Folder");lateHolder.Name="__ReplicatedSpinnerInstances";lateHolder.Parent=gui
        local lateModel=Instance.new("Model");lateModel:SetAttribute("ItemId",1410);lateModel.Parent=lateHolder
        Instance.new("Part",lateModel).Name="Handle"
        waitFor(function()
            local current=catalog.Panel.Items:FindFirstChild("Item_1410")
            return current and current.BackgroundColor3==Color3.fromRGB(25,54,43)
        end)
        lateHolder:Destroy()
        catalog.Panel.Search.Text="1390";task.wait()
        lateTool=Instance.new("Tool");lateTool:SetAttribute("ItemId",1390)
        local latePart=Instance.new("Part",lateTool);latePart.Name="Handle";latePart.Anchored=true;latePart.CanTouch=false
        lateTool.Parent=workspace
        waitFor(function()
            local current=catalog.Panel.Items:FindFirstChild("Item_1390")
            return current and current.BackgroundColor3==Color3.fromRGB(25,54,43)
        end)
        lateTool:Destroy()
        catalog.Panel.Search.Text="1410";task.wait()
        assert(catalog.Panel.Items.Item_1410.BackgroundColor3==Color3.fromRGB(25,54,43),"Late preview snapshots survive native cleanup")
    end)
    if catalog then catalog:Destroy()end
    holder:Destroy();active:Destroy()
    if lateHolder then lateHolder:Destroy()end
    if lateTool then lateTool:Destroy()end
    assert(ok,message)
    return "Native fruit preview UI scan assertions passed"
end
