-- Run during a Studio playtest. The fixture cleans up its own instances.
return function(Equipment)
local folder=Instance.new("Folder",workspace);folder.Name="DropPickupRegression"
local character=Instance.new("Model",folder)
local head=Instance.new("Part",character);head.Name="Head";head.Anchored=true;head.CanCollide=false;head.CFrame=CFrame.new(1000,1003,1000)
local humanoid=Instance.new("Humanoid",character);humanoid.RequiresNeck=false
local root=Instance.new("Part",character);root.Name="HumanoidRootPart";root.Anchored=true;root.CanCollide=false;root.CFrame=CFrame.new(1000,1000,1000)
local hand=Instance.new("Part",character);hand.Name="RightHand";hand.Anchored=true;hand.CanCollide=false;hand.CFrame=root.CFrame
local backpack=assert(game:GetService("Players").LocalPlayer,"Run in a client playtest"):FindFirstChildOfClass("Backpack")
local floor=Instance.new("Part",folder);floor.Size=Vector3.new(30,1,30);floor.Anchored=true;floor.CFrame=root.CFrame*CFrame.new(0,-4,0)
local nativeSource=Instance.new("Tool",folder)
local nativeHandle=Instance.new("Part",nativeSource);nativeHandle.Name="Handle";nativeHandle.Size=Vector3.one*2.25;nativeHandle.Transparency=1
local nativeBody=Instance.new("Part",nativeSource);nativeBody.Name="Body";nativeBody.Size=Vector3.one*1.5
local nativeItem={id="999002",name="Native handle fixture",category="Fruits"}
local nativeTool=assert(Equipment.clone(nativeSource,nativeItem));nativeTool.Parent=character
local nativeRow={item=nativeItem,count=1,tool=nativeTool,equipped=true}
local source=Instance.new("Tool",folder);local originalHandle=Instance.new("Part",source);originalHandle.Name="Handle";originalHandle.Size=Vector3.new(2,2,2)
originalHandle.Transparency=1
originalHandle.Size=Vector3.new(6,6,6)
local body=Instance.new("Part",source);body.Name="Body";body.Size=Vector3.new(2,2,2)
body.CFrame=originalHandle.CFrame*CFrame.new(0,2,0)
local item={id="999001",name="Drop test",category="Fruit Skins",isPhysicalFruit=true}
local tool=assert(Equipment.clone(source,item));tool.Parent=character
local row={item=item,count=1,tool=tool,equipped=true}
local player={Character=character,FindFirstChildOfClass=function(_,class)if class=="Backpack"then return backpack end end}
local controller=Equipment.new({items={[item.id]=row,[nativeItem.id]=nativeRow}},player,function()return source end,function()end)
local ok,result=pcall(function()
 assert(controller:drop(nativeItem))
 task.wait(1.2)
 local floorTop=floor.Position.Y+floor.Size.Y/2
 assert(math.abs(nativeTool.Handle.Position.Y-floorTop-1.125)<.08,"Native Handle, not visible mesh, determines settled height")
 assert(nativeTool.Body.Position.Y-nativeTool.Body.Size.Y/2-floorTop>.25,"Keep the native gap below visible geometry")
 assert(nativeTool.Handle.CanCollide and not nativeTool:FindFirstChild("BloxCatalogDropCollider"),"Canonical fruit Handle needs no replacement collider")
 root.CFrame=nativeTool.Body.CFrame
 root.Anchored=false;root.AssemblyLinearVelocity=Vector3.new(0,-1,0)
 local nativeDeadline=os.clock()+3
 repeat task.wait(.05)until nativeTool.Parent==character or os.clock()>nativeDeadline
 assert(nativeTool.Parent==character and not nativeTool.Handle.CanCollide,"Native Handle still supports physical contact pickup")
 root.Anchored=true;root.AssemblyLinearVelocity=Vector3.zero
 assert(controller:drop(nativeItem)and not nativeTool:FindFirstChild("BloxCatalogDropCollider"),"Repeated native Drop must not recreate a mesh collider")
 controller:remove(nativeItem.id)
 root.CFrame=CFrame.new(1000,1000,1000)
 tool.Parent=character;row.equipped=true
 assert(controller:drop(item))
 task.wait(1.2)
 local bottom=tool.Body.Position.Y-tool.Body.Size.Y/2
 local floorTop=floor.Position.Y+floor.Size.Y/2
 assert(math.abs(bottom-floorTop)<.15,"Visible fruit must rest on the floor despite oversized invisible Handle")
 local stranger=Instance.new("Part",folder);stranger.Anchored=true;stranger.CanCollide=false;stranger.CFrame=tool.Handle.CFrame
 task.wait(.3)
 assert(tool.Parent==workspace,"Foreign contact must not pick up the local fruit")
 stranger:Destroy()
 root.CFrame=tool.Body.CFrame
 local deadline=os.clock()+3
 repeat task.wait(.05)until tool.Parent==character or os.clock()>deadline
 assert(tool.Parent==character,"Walking into the dropped fruit should equip it")
 assert(not tool.Handle.CanCollide and not tool.Handle.CanTouch and tool.Handle.Massless)
 assert(not tool.BloxCatalogDropCollider.CanCollide,"Disable the drop collider when held")
 assert(not tool.Handle:FindFirstChildOfClass("ProximityPrompt"))
 assert(controller:drop(item))
 local colliders=0
 for _,child in tool:GetChildren() do if child.Name=="BloxCatalogDropCollider" then colliders+=1 end end
 assert(colliders==1,"Repeated Drop reuses one collider")
 local connection=controller.dropBindings[item.id]
 controller:remove(item.id)
 assert(not connection.Connected and tool.Parent==nil,"Clear removes dropped Tool and listener")
 return "Physics contact pickup passed; foreign contact ignored; repeated Drop and Clear cleanup passed"
end)
controller:close(true);folder:Destroy();if tool.Parent then tool:Destroy()end
assert(ok,result)
return result
end
