
local entries   = ARGV[1]
local precision = ARGV[2]
local num       = redis.call('INCR', KEYS[1] .. ':num')

num = math.ceil(num / entries)

local key    = KEYS[1] .. ':' .. num
local bits   = math.floor(-(entries * math.log(precision * math.pow(0.5, num))) / 0.09061905831)
local hashes = math.floor(0.07525749892 * bits / entries)

local hash = redis.sha1hex(ARGV[3])
local h0   = tonumber(string.sub(hash, 0 , 8 ), 16)
local h1   = tonumber(string.sub(hash, 8 , 16), 16)
local h2   = tonumber(string.sub(hash, 16, 24), 16)
local h3   = tonumber(string.sub(hash, 24, 32), 16)

for i=0, hashes, 4 do
  local bit0 = (h0 +  i      * h2) % bits
  local bit1 = (h1 + (i + 1) * h2) % bits
  local bit2 = (h0 + (i + 2) * h3) % bits
  local bit3 = (h1 + (i + 3) * h3) % bits
  
  redis.call('SETBIT', key, bit0, 1)
  redis.call('SETBIT', key, bit1, 1)
  redis.call('SETBIT', key, bit2, 1)
  redis.call('SETBIT', key, bit3, 1)
end

