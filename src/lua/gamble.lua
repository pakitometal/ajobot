--! file: gamble.lua
local strm_key = KEYS[1]
local lb_key = KEYS[2]

local id = ARGV[1]
local amount = math.ceil(tonumber(ARGV[2]))
local event_version = ARGV[3]
local guild_id = ARGV[4]

redis.replicate_commands()

-- sanity checks
if amount < 1 then
    return {"err", false}
end

-- can we gamble that much?
local current = tonumber(redis.call("zscore", lb_key, id))
if not current or current < amount then
    return {"funds", false}
end

-- 25% chance to win up from 1% to 250%
local change
if math.random(0, 3) == 1 then
    change = math.ceil(math.random(1, 100) / 40 * amount)
else
    change = -amount
end

redis.call("zincrby", lb_key, change, id)

-- append data to stream
redis.call(
    "xadd", strm_key, "*",
    "version", event_version,
    "type", "gamble",
    "user_id", id,
    "guild_id", guild_id,
    "amount", change
)
return {"OK", change}
