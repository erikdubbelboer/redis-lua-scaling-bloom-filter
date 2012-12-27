
local entries   = ARGV[1]
local precision = ARGV[2]
local num       = redis.call('INCR', KEYS[1] .. ':num')

num = math.ceil(num / entries)

local key    = KEYS[1] .. ':' .. num
local bits   = math.ceil(-(entries * math.log(precision * math.pow(0.5, num))) / 0.09061905831)
local hashes = math.ceil(0.3010299957 * bits / entries)

local hash = redis.sha1hex(ARGV[3])
local h1   = tonumber(string.sub(hash, 0, 8), 16)
local h2   = tonumber(string.sub(hash, 8, 8), 16)

for i=1, hashes, 1 do
  local h = (h1 + i * h2) % bits
  redis.call('SETBIT', key, h, 1)
end

