local component = require("component")
local invoke = component.invoke

local adress = {
    center = os.getenv("CENTER_TRANSPOSER_ADRESS"),
    second = os.getenv("SECOND_TRANSPOSER_ADRESS")
}

local direction = {
    center = tonumber(os.getenv("CENTER_TRANSPOSER_DIRECTION")),
    second = tonumber(os.getenv("SECOND_TRANSPOSER_DIRECTION")),
    output = tonumber(os.getenv("OUTPUT_TRANSPOSER_DIRECTION"))
}

local function getItem(adr, dir)
    local item = invoke(adr, "getStackInSlot", dir, 1)
    if item == nil then
        return nil
    end
    return item.label
end

local function getCenterItem()
    return getItem(adress.center, direction.center)
end

local function getSecondItem()
    return getItem(adress.second, direction.second)
end

local function exportCenterItems()
    for i=1, invoke(adress.center, "getSlotStackSize", direction.center, 1) do
        invoke(adress.center, "transferItem", direction.center, direction.output, 1, 1, 1)
    end
end

return {
    getCenterItem = getCenterItem,
    getSecondItem = getSecondItem,
    exportCenterItems = exportCenterItems
}