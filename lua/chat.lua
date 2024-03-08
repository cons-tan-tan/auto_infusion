local component = require("component")

local chat = component.chat_box

local name = os.getenv("CHAT_NAME")
local radius = tonumber(os.getenv("CHAT_RADIUS"))

local function init()
    chat.setName(name)
    chat.setDistance(radius)
end

local function say(message)
    chat.say(message)
end

return {
    init = init,
    say = say
}