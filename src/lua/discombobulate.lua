--! discombobulate.lua
local strm_key = KEYS[1]
local lb_key = KEYS[2]
local exp_key = KEYS[3]

local source_id = ARGV[1]
local target_id = ARGV[2]
local offer = math.ceil(tonumber(ARGV[3]))
local seed = tonumber(ARGV[4])

-- sanity checks
if offer < 1 then
    return {"err", false}
end

-- can we discombobulate?
local ttl = tonumber(redis.call("ttl", exp_key))
if ttl > 0 then
    return {"ttl", ttl}
end

-- can we discombobulate that much?
local source_amount = tonumber(redis.call("zscore", lb_key, source_id))
if not source_amount or source_amount < offer then
    return {"funds", false}
end

-- minimum offer is 35% of the victim
local target_amount = tonumber(redis.call("zscore", lb_key, target_id))
local min_offer = math.ceil((35 / 100) * target_amount)
if not target_amount or offer < min_offer then
    return {"offer", min_offer}
end

-- dmg is 69 to 200% of offered
math.randomseed(seed)
local percent = math.random(69, 200)
local dmg = math.floor(percent / 100 * offer)
if target_amount - dmg < 0 then
    dmg = target_amount
end

-- lock for percentage done in hours
redis.call("zincrby", lb_key, -offer, source_id)
redis.call("zincrby", lb_key, -dmg, target_id)
redis.call("set", exp_key, 1, "ex", percent * 1800)

-- append data to stream
redis.call("xadd", strm_key, "*", "user_id", source_id, "amount", -offer, "type", "discombobulator")
redis.call("xadd", strm_key, "*", "user_id", target_id, "amount", -dmg, "type", "discombobulatee")
return {"OK", dmg}
