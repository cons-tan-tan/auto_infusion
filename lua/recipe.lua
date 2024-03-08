local shell = require("shell")
local json = require("json")

local data = {}

local function update()
    shell.execute("wget -f https://raw.githubusercontent.com/cons-tan-tan/auto_infusion/main/recipes.json")
    local file = io.open("recipes.json", "r")
    if file == nil then
        error("error: file not found", 0)
    end
    local text = file:read("a")
    file:close()
    data = json.decode(text)
end

local function isSub(item)
    return data.sub[item]
end

local function getRecipe(item)
    local recipe = data.recipe[item]
    if recipe == nil then
        print(item .. " : recipe not found")
        update()
        recipe = data.recipe[item]
        if recipe == nil then
            error("error: recipe not found", 0)
        end
    end
    return recipe
end

return {
    update = update,
    isSub = isSub,
    getRecipe = getRecipe
}