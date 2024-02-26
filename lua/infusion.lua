local component = require("component")
local sides = require("sides")
local invoke = component.invoke
local interface = component.me_interface
local controller = component.me_controller
local chat = component.chat_box

local rs_wand = "d836a45e-28cf-4d22-9620-0a4f2dea4067"--Infusion Claw起動用のRedstone I/O
local rs_acce = "9be974b2-ee18-454b-9e49-1989fe8e5386"--World Accelerator起動用のRedstone I/O
local rs_expo = "4e1db502-a478-4ff7-91f0-fadbfbb88ae7"--Export Busを機能させる用のRedstone I/O
local tr_wand = "deba8439-2522-42c3-a99e-2705a1526a0f"--Infusion Clawの杖管理用のTransposer
local tr_cent = "4bb9d3b6-a8e1-4f73-a0d6-dde515568383"--中央の台座管理用のTransposer
local tr_sub = "492459ac-d58f-4467-8712-cf40eade4e3e"--代替アイテム検出用のTransposer

local recipe_list = {}
local essentia_list = {}
local aspect_list = {}
local sub_list = {}
local query = {}
local add = {}
local use_sub = ""


local function wandIsFine()--杖のVisがすべて10以上かどうか
  wand_aspects = invoke(tr_wand, "getStackInSlot", sides.north, 1).aspects
  for i=1, 6 do
    if wand_aspects[i].amount <= 1000 then--ここでの1000はゲーム中の表記だと10.00vis
      return false
    end
  end
  return true
end

local function checkWand()--杖の交換
  if not wandIsFine() then
    chat.say("杖の交換を行うよ")
    print("exchanging wand: prepared")
    while invoke(tr_wand, "transferItem", sides.north, sides.south, 1, 1, 1) == 0 do
      os.sleep(1)
    end
    while invoke(tr_wand, "getSlotStackSize", sides.north, 1) == 0 do
      os.sleep(1)
    end
    chat.say("交換が完了したよ")
    print("exchanging wand: complete!")
    print("-------------------------")
  end
end

local function checkSub(check_item_name)--代替アイテムを使うかどうか
  if #sub_list == 0 then
    return false
  else
    for i=1, #sub_list do
      if sub_list[i] == check_item_name then
        return true
      end
    end
  end
  return false
end

local function scanItem()--中央台座のアイテム名を調べる
  item = invoke(tr_cent, "getStackInSlot", sides.north, 1)
  if item == nil then
    return nil
  else
    return item.label
  end
end

local function scanItemForRecipe()--代替アイテムを使うならscanItem()の返り値を上書き
  item_label = scanItem()
  if item_label == nil then
    return nil
  elseif checkSub(item_label) then
    item_sub = invoke(tr_sub, "getStackInSlot", sides.west, 1)
    if item_sub == nil then
      return nil
    else
      use_sub = " (substitute for "..item_label..")"
      return item_sub.label, item_label
    end
  else
    use_sub = ""
    return item_label, item_label
  end
end

local function itemOutput()--中央台座のアイテムをすべて搬出
  for i=1, invoke(tr_cent, "getSlotStackSize", sides.north, 1) do
    invoke(tr_cent, "transferItem", sides.north, sides.south, 1, 1, 1)
  end
end

local function remainingOutput()--周囲の台座に残ったアイテムをすべて搬出
  if #controller.getItemsInNetwork() >= 1 then
    invoke(rs_expo, "setOutput", sides.north, 15)
    chat.say("残ったアイテムを搬出するよ")
    print("remaining detected")
    while #controller.getItemsInNetwork() >= 1 do
      os.sleep(1)
    end
    invoke(rs_expo, "setOutput", sides.north, 0)
    chat.say("搬出が完了したよ")
    print("remaining exported")
  end
end

local function infusion(craft_item)--infusionを実行
  print("start infusion")
  invoke(rs_acce, "setOutput", sides.down, 15)
  invoke(rs_wand, "setOutput", sides.down, 15)
  item_now = scanItem()
  while craft_item == item_now do
    os.sleep(1)
    item_now = scanItem()
  end
  print("result detected: " .. item_now)
  print("infusion succeeded!")
  remainingOutput()
  itemOutput()
  invoke(rs_acce, "setOutput", sides.down, 0)
  invoke(rs_wand, "setOutput", sides.down, 0)
end

local function keyAmount(table)--連想配列のkey数を返す
  key_amount = 0
  for k,v in pairs(table) do
    key_amount = key_amount + 1
  end
  return key_amount
end

local function keyFind(tbl, key)--連想配列に任意のkeyを持つデータがあるか返す
  for k,v in pairs(tbl) do
    if k == key and v ~= nil then
      return true
    end
  end
  return false
end

local function dump(o)--配列の中身を一覧表示
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

local function loadData()--同一ディレクトリのデータ類を読み込む
  aspects = io.open("aspects", "r")
  for line in aspects:lines() do
    aspect_list[line] = line
  end
  aspects:close()
  print("get all aspect's name")
  sub = io.open("sub", "r")
  for line in sub:lines() do
    table.insert(sub_list, line)
  end
  sub:close()
  if #sub_list >= 1 then
    print("use substitution: " .. dump(sub_list))
  end
  recipes = io.open("recipes", "r")
  for line in recipes:lines() do
    a = 1
    b = string.find(line, ",")
    item_name = string.sub(line, 1, b-1)
    a = b
    if keyFind(recipe_list, item_name) then
      chat.say("エラー：キーアイテムが重複")
      error("error: key_item overlapping "..'"'..item_name..'"', 0)
    else
      recipe_list[item_name] = {}
    end
    mark_end, _ = string.find(line, ",,", a+1)
    if mark_end == nil then
      mark_end = string.len(line)
    end
    while a ~= mark_end do
      b = string.find(line, ":", a+1)
      as_name = string.sub(line, a+1, b-1)
      a = b
      b = string.find(line, ",", a+1)
      as_amount = string.sub(line, a+1, b-1)
      a = b
      if keyFind(aspect_list, as_name) then
        recipe_list[item_name][as_name] = tonumber(as_amount)
      else
        chat.say("エラー：無効な相を検出")
        error("error: invalid aspect "..'"'..as_name..'"', 0)
      end
    end
    print("["..item_name.."] = " .. dump(recipe_list[item_name]))
  end
  recipes:close()
  print("-------------------------")
  print("loading data: complete!")
end

local function orderEssentia(essentia_name, essentia_amount)--任意のエッセンシアを注文
  request = interface.getCraftables({aspect = essentia_name})
  if keyAmount(request) == 0 then
    return nil
  else
    return request[1].request(essentia_amount)
  end
end

local function getEssentia()--ネットワーク上のエッセンシアのリストを記録
  list_raw = interface.getEssentiaInNetwork()
  for i=1 ,#list_raw do
    as_name = list_raw[i].name
    as_amount = list_raw[i].amount
    _, start = string.find(as_name, "gaseous")
    stop, _ = string.find(as_name, "essentia")
    essentia_list[string.sub(as_name, start+1, stop-1)] = as_amount
  end
end

local function enoughEssentia(craft_item_name)--足りないエッセンシアを補充
  getEssentia()
  shortage_essentia = 0
  for a,b in pairs(recipe_list[craft_item_name]) do
    amount = essentia_list[a]
    if amount == nil then
      amount = 0
    end
    if amount < b + 64 then
      shortage_essentia = shortage_essentia + 1
      order_amount = b+64-amount
      if keyFind(add, a) then
        order_amount = order_amount + add[a]
      end
      if not keyFind(query, a) then
        query[a] = orderEssentia(a, order_amount)
        if query[a] == nil then--注文できないエッセンシアが足りなかった場合
          chat.say(a .. "が" .. order_amount .. "足りないよ")
          print(a.."("..order_amount.."): " .. "missing recipe")
        elseif query[a].isCanceled() then--エッセンシアのレシピはあるが注文できなかった場合
          query[a] = nil
          chat.say(a .. "を" .. order_amount .. "注文できなかったよ")
          print(a.."("..order_amount.."): " .. "uncraftable")
        else--注文できた場合
          chat.say(a .. "を" .. order_amount .. "注文したよ")
          print(a.."("..order_amount.."): " .. "requested")
        end
      else
        if query[a].isDone() == true then--注文後に別要因(crucibleなど)でエッセンシアが減った場合
          query[a] = nil
          add[a] = order_amount + 10
          chat.say(a.."は注文後に"..order_amount.."不足したよ")
          print(a.."("..order_amount.."): " .. "lost after crafting")
        end
      end
    end
  end
  if shortage_essentia == 0 then
    query = {}
    add = {}
    return true
  else
    return false
  end
end

local function initialize()--初期化
  invoke(rs_acce, "setOutput", sides.down, 0)
  invoke(rs_wand, "setOutput", sides.down, 0)
  invoke(rs_expo, "setOutput", sides.north, 0)
  chat.setName("Infusion")
  chat.setDistance(30)
  loadData()
end


initialize()--ここからメイン処理
while true do
  print("-------------------------")
  checkWand()
  key_item, cent_item = scanItemForRecipe()
  while key_item == nil or recipe_list[key_item] == nil do
    os.sleep(1)
    key_item, cent_item = scanItemForRecipe()
  end
  print("key_item detected: " .. key_item .. use_sub)
  while not enoughEssentia(key_item) do
    os.sleep(1)
  end
  infusion(cent_item)
end