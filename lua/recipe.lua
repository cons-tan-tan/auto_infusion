local shell = require("shell")
local json = require("json")

local recipes = {}

local function update()
    shell.execute("wget -f https://raw.githubusercontent.com/cons-tan-tan/auto_infusion/main/recipes.json")
    local file = io.open("recipes.json", "r")
    if file == nil then
        error("error: file not found", 0)
    end
    local data = file:read("a")
    file:close()
    recipes = json.decode(data)
end

local function isSub(item)
    return recipes.sub[item]
end

local function getRecipe(item)
    local recipe = recipes.recipes[item]
    if recipe == nil then
        print(item .. " : recipe not found")
        update()
        recipe = recipes.recipes[item]
        if recipe == nil then
            error("error: recipe not found", 0)
        end
    end
    return recipe
end

update()
return {
    update = update,
    isSub = isSub,
    getRecipe = getRecipe
}