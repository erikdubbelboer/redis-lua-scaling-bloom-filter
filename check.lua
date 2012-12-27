
local entries   = ARGV[1]
local precision = ARGV[2]
local num       = redis.call('GET', KEYS[1] .. ':num')

num = math.ceil(num / entries)

local hash = redis.sha1hex(ARGV[3])
local h    = { }

h[0] = tonumber(string.sub(hash, 0 , 8 ), 16)
h[1] = tonumber(string.sub(hash, 8 , 16), 16)
h[2] = tonumber(string.sub(hash, 16, 24), 16)
h[3] = tonumber(string.sub(hash, 24, 32), 16)

for n=1, num, 1 do
  local bits   = math.floor(-(entries * math.log(precision * math.pow(0.5, n))) / 0.09061905831)
  local hashes = math.floor(0.3010299957 * bits / entries)
  local key    = KEYS[1] .. ':' .. n
  local found  = true

  for i=1, hashes, 1 do
    local j   = i % 2
    local bit = (h[j] + i * h[2 + j]) % bits

    if redis.call('GETBIT', key, bit) == 0 then
      found = false
      break
    end
  end

  if found then
    return 1
  end
end

return 0

