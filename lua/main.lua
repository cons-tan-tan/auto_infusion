local component = require("component")
local event = require("event")
local thread = require("thread")

local claw = require("claw")
local accelerator = require("accelerator")
local interface = require("interface")
local pedestal = require("pedestal")
local recipe = require("recipe")

local rs = component.redstone
local matrix = component.blockstonedevice_2
local controller = component.me_controller

local direction = tonumber(os.getenv("EXPORTBUS_REDSTONE_DIRECTION"))
local margin = tonumber(os.getenv("ORDER_MARGIN"))

local command
local command_list = {}

local function exportRemainings()
    if #controller.getItemsInNetwork() >= 1 then
        rs.setOutput(direction, 15)
        while #controller.getItemsInNetwork() >= 1 do
          os.sleep(1)
        end
        rs.setOutput(direction, 0)
    end
end

local function getInsufficientEssentia()
    return matrix.getAspects().aspects
end

local function refillEssentia(order_list)
    local essentia = interface.getEssentiaList()
    for i=1, #order_list do
        local order = {
            aspect = order_list[i].aspect,
            amount = order_list[i].amount
        }
        local amount = essentia[order.aspect]
        if amount == nil then
            amount = 0
        end
        if amount < order.amount + margin then
            local q = interface.orderEssentia(order.aspect, order.amount + margin - amount)
            if q == nil then
                print(order.aspect .. " recipe not found")
                return false
            elseif q.isCanceled() then
                print(order.aspect .. " unable to order")
                return false
            else
                print(order.aspect .. " ordered")
            end
        end
    end
    return true
end

local function infusion(product)
    accelerator.turnOn()
    claw.trigger()
    while pedestal.getCenterItem() ~= product do
        os.sleep(1)
    end
    claw.init()
    accelerator.turnOff()
    exportRemainings()
    pedestal.exportCenterItems()
end

local function init()
    recipe.update()
    rs.setOutput(direction, 0)
    accelerator.turnOff()
    claw.init()
end

thread.create(function()
    while true do
        local _, _, _, message = event.pull("chat_message")
        if string(message, 1, 1) == "@" then
            local slug = string.sub(message, 2)
            if command_list[slug] ~= nil then
                command = slug
            end
        end
    end
end)

init()
while true do
    if not claw.isFine() then
        claw.waitForReady()
    end

    local item = pedestal.getCenterItem()
    if item == nil then
        os.sleep(1)
        goto continue
    elseif recipe.isSub(item) then
        item = pedestal.getSecondItem()
    end

    local data = recipe.getRecipe(item)
    while not refillEssentia(data.essentia) do
        os.sleep(1)
    end

    infusion(data.product)
    ::continue::
end