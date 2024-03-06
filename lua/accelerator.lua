local component = require("component")
local invoke = component.invoke

local adress = {
    os.getenv("CLAW_ACCELERATOR_ADRESS"),
    os.getenv("MATRIX_ACCELERATOR_ADRESS")
}

local function turnOn()
    for i=1, #adress do
        invoke(adress[i], "setWorkAllowed", true)
    end
end

local function turnOff()
    for i=1, #adress do
        invoke(adress[i], "setWorkAllowed", false)
    end
end

return {
    turnOn = turnOn,
    turnOff = turnOff
}