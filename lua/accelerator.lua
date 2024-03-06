local component = require("component")
local invoke = component.invoke

local adress = {
    "d1985e11-7004-4126-80e0-8bc13b9410cc",
    "6efadad3-4279-406d-8b03-56f0959c96d1"
}

local function setOn()
    for i=1, #adress do
        invoke(adress[i], "setWorkAllowed", true)
    end
end

local function setOff()
    for i=1, #adress do
        invoke(adress[i], "setWorkAllowed", false)
    end
end

return {
    setOn = setOn,
    setOff = setOff
}