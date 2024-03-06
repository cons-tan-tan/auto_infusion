local component = require("component")
local interface = component.me_interface

local util = require("util")

local function orderEssentia(essentia_name, essentia_amount) -- 任意のエッセンシアを注文
    local request = interface.getCraftables({aspect = essentia_name})
    if util.getTableLength(request) == 0 then
        return nil -- レシピが存在しない場合nilを返す
    else
        return request[1].request(essentia_amount) -- レシピが存在する場合は注文し、その結果を返す
    end
end

local function getEssentiaList() -- ネットワーク上のエッセンシアのリストを記録
    local list_raw = interface.getEssentiaInNetwork()
    local list = {}
    for i=1 ,#list_raw do
        local raw_name = list_raw[i].name
        local _, start = string.find(raw_name, "gaseous")
        local stop, _ = string.find(raw_name, "essentia")
        local name = string.sub(raw_name, start+1, stop-1)
        list[name] = list_raw[i].amount
    end
    return list
end

return {
    orderEssentia = orderEssentia,
    getEssentiaList = getEssentiaList
}