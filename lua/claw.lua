local component = require("component")
local invoke = component.invoke
local rs = component.redstone

local adress = os.getenv("CRAW_TRANSPOSER_ADRESS")

local direction = {
    redstone = tonumber(os.getenv("CRAW_REDSTONE_DIRECTION")),
    transposer = tonumber(os.getenv("CRAW_TRANSPOSER_DIRECTION"))
}


local function init()
    rs.setOutput(direction.redstone, 0)
end

local function trigger()
    rs.setOutput(direction.redstone, 15)
end

local function isActive()
    return rs.getOutput(direction.redstone) > 0
end

local function isFine()
    local vis = invoke(adress, "getStackInSlot", direction.transposer, 1).aspects
    for i=1, 6 do
        if vis[i].amount <= 1000 then --centi-vis単位
            return false
        end
    end
    return true
end

return {
    init = init,
    trigger = trigger,
    isActive = isActive,
    isFine = isFine
}