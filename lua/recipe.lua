local shell = require("shell")
local json = require("json")

local data = {}

local function download()
    local file_name = "recipes.json"
    local zlib_name = file_name .. ".zlib"
    local url = "https://cons-tan-tan.github.io/auto_infusion/" .. zlib_name
    print("Download " .. url)
    shell.execute(string.format("wget -f %s > /dev/null", url))
    print("Inflate " .. zlib_name .. " to " .. file_name)
    shell.execute(string.format("inflate %s > %s", zlib_name, file_name))
    print("Remove " .. zlib_name)
    shell.execute(string.format("rm %s", zlib_name))
    print("Complete!")
end

local function update()
    download()
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
    if recipe.amount == nil then
        recipe.amount = 1
    end
    return recipe
end

return {
    update = update,
    isSub = isSub,
    getRecipe = getRecipe
}