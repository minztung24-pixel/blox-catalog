return function(FruitAnimations)
    local item={id="fixture",category="Fruits"}
    local tool=Instance.new("Tool")
    local handle=Instance.new("Part",tool);handle.Name="Handle"
    local fruit=Instance.new("Model",tool);fruit.Name="Fruit"
    Instance.new("AnimationController",fruit)
    local idle=Instance.new("Animation",fruit);idle.Name="Idle";idle.AnimationId="rbxassetid://1"
    local emitter=Instance.new("ParticleEmitter",handle);emitter.Enabled=false;emitter.Rate=7
    local ok,message=pcall(function()
        assert(not FruitAnimations.apply(tool,item),"Unknown fruits keep their authored animation")
        local reference={signature=FruitAnimations.signature(tool),originalId="rbxassetid://1",animationId="rbxassetid://2"}
        FruitAnimations.references[item.id]=reference
        local extra=Instance.new("Bone",handle)
        assert(not FruitAnimations.apply(tool,item) and idle.AnimationId==reference.originalId,"Do not apply a clip to a different rig")
        extra:Destroy()
        idle.AnimationId="rbxassetid://3"
        assert(not FruitAnimations.apply(tool,item) and idle.AnimationId=="rbxassetid://3","Keep newer or native IDs")
        idle.AnimationId=reference.originalId
        assert(not FruitAnimations.apply(tool,{id=item.id,category="Swords"}),"Match the fruit category")
        assert(FruitAnimations.apply(tool,item) and idle.AnimationId==reference.animationId,"Correct the verified rig and old ID")
        assert(not FruitAnimations.apply(tool,item),"Do not apply twice")
        assert(not emitter.Enabled and emitter.Rate==7,"Animation corrections preserve authored FX")
        idle:Destroy();reference.originalId=""
        assert(FruitAnimations.apply(tool,item) and fruit.Idle.AnimationId==reference.animationId,"A verified rig may be missing its Animation instance")
        fruit.Idle:Destroy();fruit.AnimationController:Destroy()
        assert(not FruitAnimations.apply(tool,item) and not fruit:FindFirstChild("Idle"),"Never invent a missing rig")
    end)
    FruitAnimations.references[item.id]=nil;tool:Destroy()
    assert(ok,message)
    return "Fruit animation reference assertions passed"
end
