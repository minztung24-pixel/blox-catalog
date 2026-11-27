-- Temporary local menu only; no fruit actions or remotes.
assert(game.GameId==994732206,"Run in Blox Fruits")
local mode=...
if mode=="added"then
    require(game.ReplicatedStorage.Notification).new("Fruit added to backpack."):Display()
    return
end
local controller=require(game.ReplicatedStorage.DialogueController)
assert(not controller.getActiveDialogue(),"Close the current dialogue first")
local dialogue=controller.new()
dialogue:setTitle("Blox Fruit")
dialogue:setLayout({Cinematic=true})
dialogue:addPage(function(page)
    if mode=="stored"then
        page:addText("[Blox Fruit stored.]<AnimateYield=3>")
        page:noCancel()
        return
    end
    page:addText("What do you wish to do with this Blox Fruit?<AnimateYield=3>")
    for _,name in ipairs({"Eat","Drop","Store"})do
        page:addOption(function(option)option:setText(name);option:setType("Chat")end)
    end
    page:setCancelText("Nevermind")
end)
dialogue:build()
if mode=="stored"then require(game.ReplicatedStorage.Notification).new("Blox Fruit stored."):Display()end
task.delay(15,function()
    local active=controller.getActiveDialogue()
    if active and active._dialogue==dialogue then controller.close()end
end)
print("Native cinematic menu preview: no actions; closes after 15 seconds")
controller.start(dialogue)
print("Native cinematic menu preview closed")
