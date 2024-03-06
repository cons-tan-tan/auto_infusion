local function getTableLength(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
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

return {
  getTableLength = getTableLength,
  dump = dump
}