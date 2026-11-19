local Database = require(script.Parent.Data)
local Catalog = {byId = {}, byToolName = {}, count = 0, databases = Database, categories = {"Fruits", "Permanent", "Fruit Skins", "Premium", "Swords", "Guns", "Skills"}}
local function toolName(name, id)
    local previous = Catalog.byToolName[name]
    if previous == nil then Catalog.byToolName[name] = id
    elseif previous ~= id then Catalog.byToolName[name] = false end
end
for _, category in ipairs(Catalog.categories) do
    for _, item in ipairs(Database[category]) do
        assert(not Catalog.byId[item.id], "Duplicate catalog ID")
        Catalog.byId[item.id] = item
        Catalog.count += 1
        if item.idType == "PhysicalMoveset" then
            toolName(item.storageKey .. " Fruit", item.id)
            toolName(item.name .. " Fruit", item.id)
        elseif item.idType == "Moveset" then
            toolName(item.storageKey, item.id); toolName(item.name, item.id)
        end
    end
end
function Catalog.matches(item, query)
    local text = table.concat({item.name, item.id, item.rarity, item.title, item.storageKey}, " "):lower()
    query = query:match("^%s*(.-)%s*$"):lower()
    return text:find(query, 1, true) ~= nil
end
function Catalog.search(query, category)
    local result = {}
    for _, item in ipairs(Database[category] or {}) do
        if Catalog.matches(item, query) then table.insert(result, item) end
    end
    return result
end
return Catalog
