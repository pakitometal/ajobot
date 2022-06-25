--! file: use_cross.lua
local strm_key = KEYS[1]
local inventory_key = KEYS[2]
local vampire_key = KEYS[3]

local id = ARGV[1]
local item = ARGV[2]

-- ensure we actually own the item
local stack = tonumber(redis.call("hget", inventory_key, item))
if not stack or stack < 1 then
    return {"err", false}
end

-- use the item, decrease stack
redis.call("hincrby", inventory_key, item, -1)

-- if there is no vampire, you just used the item
local vampire_level = tonumber(redis.call("get", vampire_key))
if not vampire_level or vampire_level < 1 then
    return {"OK", 0}
end

-- FIXME: due to how the legacy vampire system works, we have to delete the
-- vampire key when it's 2 or lower
local res
if vampire_level <= 2 then
    redis.call("del", vampire_key)
    res = 0
else
    res = redis.call("decrby", vampire_key, 1)
end

redis.call("xadd", strm_key, "*", "user_id", id, "item", item, "quantity", -1, "type", "item_used")
return {"OK", res}
