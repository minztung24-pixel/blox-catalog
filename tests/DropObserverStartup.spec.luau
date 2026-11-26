return function(source)
    local boundary=assert(source:find('local filename=',1,true))
    local startup=source:sub(1,boundary-1).."\nreturn tool"
    local character=Instance.new("Model")
    local weapon=Instance.new("Tool",character);weapon.Name="Sword"
    local visual=Instance.new("Tool",character);visual.Name="Catalog Fruit"
    visual:SetAttribute("BloxCatalogOwned",true)
    Instance.new("Part",visual).Name="Handle"
    local fruit=Instance.new("Tool");fruit.Name="Spin Fruit"
    Instance.new("Part",fruit).Name="Handle"
    local clock,writes=0,0
    local function run(holdLater)
        local fn=assert(loadstring(startup))
        local fakeGame={}
        function fakeGame:GetService(name)
            assert(name=="Players")
            return {LocalPlayer={Character=character}}
        end
        setfenv(fn,setmetatable({
            game=fakeGame,
            os={clock=function()return clock end},
            task={wait=function()
                clock+=.2
                if holdLater and clock>=1 then fruit.Parent=character end
            end},
            print=function()end,warn=function()end,
            writefile=function()writes+=1 end,
        },{__index=getfenv()}))
        return fn()
    end
    local ok,message=pcall(function()
        assert(run(true)==fruit and clock>=1,"Wait for the held genuine fruit")
        fruit.Parent=nil
        clock=0
        assert(run(false)==nil and clock>=90 and clock<91,"Stop waiting after the deadline")
        assert(writes==0,"Startup must not overwrite the previous Drop report")
        assert(weapon.Parent==character and visual.Parent==character,"Preserve existing Tools")
    end)
    fruit:Destroy();character:Destroy()
    assert(ok,message)
    return "Drop startup wait, timeout, Tool filtering and report preservation assertions passed"
end
