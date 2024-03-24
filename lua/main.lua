local component = require("component")
local event = require("event")

local claw = require("claw")
local accelerator = require("accelerator")
local interface = require("interface")
local pedestal = require("pedestal")
local recipe = require("recipe")
local chat = require("chat")

local rs = component.redstone
local matrix = component.blockstonedevice_2
local controller = component.me_controller

local direction = tonumber(os.getenv("EXPORTBUS_REDSTONE_DIRECTION"))
local margin = tonumber(os.getenv("ORDER_MARGIN"))

local queue = nil
local commands = {
    update = recipe.update,
}

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

local q = {}

local function refillEssentia(order_list)
    local essentia = interface.getEssentiaList()
    local is_enough = true
    for aspect, amount in pairs(order_list) do
        local remaining = essentia[aspect]
        if remaining == nil then
            remaining = 0
        end
        if remaining < amount + margin then
            is_enough = false
            local order_amount = amount + margin - remaining
            if q[aspect] == nil then
                q[aspect] = interface.orderEssentia(aspect, order_amount)
                if q[aspect] == nil then
                    print(aspect .. " recipe not found")
                elseif q[aspect].isCanceled() then
                    q[aspect] = nil
                    print(aspect .. " unable to order")
                else
                    print(aspect .. " ordered")
                end
            else
                if q[aspect].isDone() then
                    q[aspect] = nil
                    print(aspect.."("..order_amount.."): " .. "lost after crafting")
                end
            end
        end
    end
    if is_enough then
        q = {}
        return true
    else
        return false
    end
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

local function callback(_, _, _, message)
    if string(message, 1, 1) == "@" then
        local slug = string.sub(message, 2)
        if type(commands[slug]) == "function" then
            queue = slug
        end
    end
end

local function init()
    recipe.update()
    rs.setOutput(direction, 0)
    accelerator.turnOff()
    claw.init()
    chat.init()
    event.listen("chat_message", callback)
end

init()
while true do
    if queue ~= nil then
        queue = nil
        commands[queue]()
    end

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