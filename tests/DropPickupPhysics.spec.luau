-- Run during a Studio playtest. The fixture cleans up its own instances.
return function(Equipment)
local folder=Instance.new("Folder",workspace);folder.Name="DropPickupRegression"
local character=Instance.new("Model",folder)
Instance.new("Humanoid",character)
local root=Instance.new("Part",character);root.Name="HumanoidRootPart";root.Anchored=true;root.CanCollide=false;root.CFrame=CFrame.new(1000,1000,1000)
local hand=Instance.new("Part",character);hand.Name="RightHand";hand.Anchored=true;hand.CanCollide=false;hand.CFrame=root.CFrame
local backpack=Instance.new("Folder",folder)
local floor=Instance.new("Part",folder);floor.Size=Vector3.new(30,1,30);floor.Anchored=true;floor.CFrame=root.CFrame*CFrame.new(0,-4,0)
local source=Instance.new("Tool",folder);local originalHandle=Instance.new("Part",source);originalHandle.Name="Handle";originalHandle.Size=Vector3.new(2,2,2)
originalHandle.Transparency=1
originalHandle.Size=Vector3.new(6,6,6)
local body=Instance.new("Part",source);body.Name="Body";body.Size=Vector3.new(2,2,2)
body.CFrame=originalHandle.CFrame*CFrame.new(0,2,0)
local item={id="999001",name="Drop test",category="Fruits"}
local tool=assert(Equipment.clone(source,item));tool.Parent=character
local row={item=item,count=1,tool=tool,equipped=true}
local player={Character=character,FindFirstChildOfClass=function(_,class)if class=="Backpack"then return backpack end end}
local controller=Equipment.new({items={[item.id]=row}},player,function()return source end,function()end)
local ok,result=pcall(function()
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
