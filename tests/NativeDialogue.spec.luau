return function(NativeDialogue)
    local tool=Instance.new("Tool");tool:SetAttribute("BloxCatalogOwned",true)
    local starts,closes,actions=0,0,0
    local current,choose,during,fail=nil,"Drop",nil,false
    local native={getActiveDialogue=function()return current end,close=function()closes+=1;current=nil end}
    function native.new()
        local dialogue={}
        function dialogue:setTitle(value)self.title=value end
        function dialogue:setSubtitle(value)self.subtitle=value end
        function dialogue:addPage(build)self.buildPage=build end
        function dialogue:build()self.built=true end
        return dialogue
    end
    function native.startForTool(actual,dialogue,delay)
        assert(delay==nil,"Use the game's default interaction timing")
        assert(actual==tool and dialogue.built and dialogue.title=="Blox Fruit" and dialogue.subtitle==nil)
        starts+=1;current={_dialogue=dialogue}
        local page={options={}}
        function page:addText(value)self.text=value end
        function page:setCancelText(value)self.cancel=value end
        function page:addOption(build)
            local option={setText=function(self,value)self.label=value end,setType=function(self,value)self.kind=value end,onSelected=function(self,callback)self.select=callback end}
            build(option);table.insert(self.options,option)
        end
        dialogue.buildPage(page)
        assert(page.cancel=="Nevermind" and #page.options==3)
        assert(page.text=="What do you wish to do with this Blox Fruit?<AnimateYield=3>")
        for _,option in ipairs(page.options) do assert(option.kind=="Chat");if option.label==choose then option.select() end end
        if during then during() end
        if fail then error("fixture render failed") end
        current=nil
    end
    local binding=NativeDialogue.new(native)
    local callbacks={Drop=function()assert(current==nil);actions+=1 end}
    local ok,err=pcall(function()
        assert(binding:show(tool,callbacks) and starts==1 and actions==1)
        current={_dialogue={}}
        assert(not binding:show(tool,callbacks) and starts==1 and closes==0,"Do not replace another native menu")
        binding:dismiss();assert(current and closes==0)
        current=nil;choose=nil;during=function()binding:dismiss()end
        assert(binding:show(tool,callbacks) and closes==1)
        during=nil;fail=true
        assert(not binding:show(tool,callbacks) and closes==2 and current==nil,"Failed rendering must release the owned dialogue")
        fail=false;choose="Drop";during=function()binding:close()end
        assert(not binding:show(tool,callbacks) and actions==1,"Closing while open must prevent a delayed action")
        assert(not binding:show(tool,callbacks))
    end)
    binding:close();tool:Destroy();assert(ok,err)
    return "Native dialogue assertions passed"
end
