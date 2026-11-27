local NativeDialogue = {}

function NativeDialogue.new(controller)
    assert(typeof(controller)=="table","Native dialogue controller is unavailable")
    for _,name in ipairs({"new","start","getActiveDialogue","close"}) do
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
        local connections={}
        local ok,message=pcall(function()
            local dialogue=controller.new()
            self.dialogue=dialogue
            dialogue:setTitle("Blox Fruit")
            -- The native cinematic layout bypasses the account's DialogueV1 legacy theme.
            dialogue:setLayout({Cinematic=true})
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
            -- startForTool lazily requires another game module, which fails in the executor context.
            local function dismissOwned()
                if self.dialogue==dialogue then self:dismiss() end
            end
            table.insert(connections,tool.Unequipped:Connect(dismissOwned))
            table.insert(connections,tool.Destroying:Connect(dismissOwned))
            controller.start(dialogue)
            -- Store destroys the Tool; its listeners must not dismiss the result page.
            for _,connection in ipairs(connections)do connection:Disconnect()end
            table.clear(connections)
            if self.closed then return end
            if selected and actions[selected]then
                local success,reason=actions[selected]()
                if success==false then error(tostring(reason or "Fruit action failed"),0)end
                if selected=="Store"and success==true and not self.closed then
                    assert(not controller.getActiveDialogue(),"Finish the current game dialogue first")
                    local result=controller.new()
                    self.dialogue=result
                    result:setTitle("Blox Fruit")
                    result:setLayout({Cinematic=true})
                    result:addPage(function(page)
                        page:addText("[Blox Fruit stored.]<AnimateYield=3>")
                        page:noCancel()
                    end)
                    result:build()
                    controller.start(result)
                end
            end
        end)
        for _,connection in ipairs(connections) do connection:Disconnect() end
        if not ok then self:dismiss() end
        self.running=false
        self.dialogue=nil
        if not ok then return false,tostring(message) end
        if self.closed then return false,"Native fruit menu was closed" end
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
