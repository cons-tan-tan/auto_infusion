local component = require("component")
local rs = component.redstone


local direction = {
    redstone = os.getenv("CRAW_REDSTONE_DIRECTION"),
    transposer = os.getenv("CRAW_TRANSPOSER_DIRECTION")
}


function init()
    rs.setOutput(direction.redstone, 0)
end

function trigger()
    rs.setOutput(direction.redstone, 15)
end

function isActive()
    return rs.getOutput(direction.redstone) > 0
end


local craw = {
    init = init,
    trigger = trigger,
    isActive = isActive
}

return craw