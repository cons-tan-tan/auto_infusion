local component = require("component")
local rs = component.redstone


local direction = {
    redstone = os.getenv("CRAW_REDSTONE_DIRECTION"),
    transposer = os.getenv("CRAW_TRANSPOSER_DIRECTION")
}


function init()
    rs.setOutput(tonumber(direction.redstone), 0)
end

function trigger()
    rs.setOutput(tonumber(direction.redstone), 15)
end

function isActive()
    return rs.getOutput(tonumber(direction.redstone)) > 0
end


return {
    init = init,
    trigger = trigger,
    isActive = isActive
}