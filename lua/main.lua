local component = require("component")
local event = require("event")
local thread = require("thread")

local claw = require("claw")
local accelerator = require("accelerator")

local matrix = component.blockstonedevice_2

local command = ""
local command_list = {
    update = function()
        
    end,
}

local function getInsufficientEssentia()
    return matrix.getAspects().aspects
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