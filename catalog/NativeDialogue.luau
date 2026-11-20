local NativeDialogue = {}

function NativeDialogue.new(controller)
    assert(typeof(controller)=="table","Native dialogue controller is unavailable")
    for _,name in ipairs({"new","startForTool","getActiveDialogue","close"}) do
        assert(typeof(controller[name])=="function","Native dialogue API unavailable: "..name)
    end
    local binding = {controller=controller,running=false,closed=false}
    function binding:dismiss()
        if not self.dialogue then return end
        local ok,active=pcall(controller.getActiveDialogue)
        -- Never close an NPC or genuine fruit dialogue opened by somebody else.
        if ok and active and active._dialogue==self.dialogue then pcall(controller.close) end
    end
    function binding:show(tool,actions)
        if self.closed then return false,"Native fruit menu is closed" end
        if self.running or controller.getActiveDialogue() then return false,"Finish the current game dialogue first" end
        if not tool:GetAttribute("BloxCatalogOwned") then return false,"Use the original menu for real fruit" end
        self.running=true
        local selected
        local ok,message=pcall(function()
            local dialogue=controller.new()
            self.dialogue=dialogue
            dialogue:setTitle("Blox Fruit")
            dialogue:addPage(function(page)
                page:addText("What do you wish to do with this Blox Fruit?<AnimateYield=3>")
                for _,name in ipairs({"Eat","Drop","Store"}) do
                    page:addOption(function(option)
                        option:setText(name)
                        option:setType("Chat")
                        option:onSelected(function()selected=name end)
                    end)
                end
                page:setCancelText("Nevermind")
            end)
            dialogue:build()
            controller.startForTool(tool,dialogue)
        end)
        if not ok then self:dismiss() end
        self.running=false
        self.dialogue=nil
        if not ok then return false,tostring(message) end
        if self.closed then return false,"Native fruit menu was closed" end
        if selected and actions[selected] then
            local called,err=pcall(actions[selected])
            if not called then return false,tostring(err) end
        end
        return true
    end
    function binding:close()
        self.closed=true
        self:dismiss()
    end
    return binding
end

function NativeDialogue.connect()
    assert(typeof(getloadedmodules)=="function","Open a game dialogue once, then retry")
    local module=game:GetService("ReplicatedStorage"):FindFirstChild("DialogueController")
    assert(module and module:IsA("ModuleScript"),"Game dialogue controller is unavailable")
    local loaded=false
    for _,candidate in pairs(getloadedmodules()) do if candidate==module then loaded=true;break end end
    assert(loaded,"Open a game dialogue once, then retry")
    local result
    local worker=task.spawn(function()result=table.pack(pcall(require,module))end)
    local deadline=os.clock()+3
    while not result and os.clock()<deadline do task.wait(0.03) end
    if not result then pcall(task.cancel,worker);error("Cached dialogue controller timed out") end
    assert(result[1],result[2])
    return NativeDialogue.new(result[2])
end

return NativeDialogue
