
local entries   = ARGV[1]
local precision = ARGV[2]
local num       = redis.call('GET', KEYS[1] .. ':num')

num = math.ceil(num / entries)

local hash = redis.sha1hex(ARGV[3])
local h0   = tonumber(string.sub(hash, 0 , 8 ), 16)
local h1   = tonumber(string.sub(hash, 8 , 16), 16)
local h2   = tonumber(string.sub(hash, 16, 24), 16)
local h3   = tonumber(string.sub(hash, 24, 32), 16)

for n=1, num, 1 do
  local bits   = math.floor(-(entries * math.log(precision * math.pow(0.5, n))) / 0.09061905831)
  local hashes = math.floor(0.07525749892 * bits / entries)
  local key    = KEYS[1] .. ':' .. n
  local found  = true

  for i=0, hashes, 4 do
    local bit0 = (h0 +  i      * h2) % bits
    local bit1 = (h1 + (i + 1) * h2) % bits
    local bit2 = (h0 + (i + 2) * h3) % bits
    local bit3 = (h1 + (i + 3) * h3) % bits

    if redis.call('GETBIT', key, bit0) == 0 or
       redis.call('GETBIT', key, bit1) == 0 or
       redis.call('GETBIT', key, bit2) == 0 or
       redis.call('GETBIT', key, bit3) == 0 then
      found = false
      break
    end
  end

  if found then
    return 1
  end
end

return 0

