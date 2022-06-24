--! file: use_cross.lua
local inventory_key = KEYS[1]
local vampire_key = KEYS[2]

local item = ARGS[1]

-- ensure we actually own the item
local stack = tonumber(redis.call("hget", inventory_key, item))
if not stack or stack < 1 then
    return {"err", false}
end

-- decrease stack and vampire level
redis.call("hdecrby", inventory_key, item, 1)
local res = redis.call("decrby", vampire_key, 1)
return {"OK", res}
