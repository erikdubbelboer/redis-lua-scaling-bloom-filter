
local entries   = ARGV[2]
local precision = ARGV[3]
local index     = redis.call('GET', ARGV[1] .. ':count')

if not index then
  return 0
end

index = math.ceil(index / entries)

local hash = redis.sha1hex(ARGV[4])

-- This uses a variation on:
-- 'Less Hashing, Same Performance: Building a Better Bloom Filter'
-- http://www.eecs.harvard.edu/~kirsch/pubs/bbbf/esa06.pdf
local h = { }
h[0] = tonumber(string.sub(hash, 0 , 8 ), 16)
h[1] = tonumber(string.sub(hash, 8 , 16), 16)
h[2] = tonumber(string.sub(hash, 16, 24), 16)
h[3] = tonumber(string.sub(hash, 24, 32), 16)

-- Based on the math from: http://en.wikipedia.org/wiki/Bloom_filter#Probability_of_false_positives
-- Combined with: http://www.sciencedirect.com/science/article/pii/S0020019006003127
-- 0.693147180 = ln(2)
-- 0.480453013 = ln(2)^2
local maxk = math.floor(0.693147180 * math.floor((entries * math.log(precision * math.pow(0.5, index))) / -0.480453013) / entries)
local b    = { }

for i=1, maxk do
  table.insert(b, h[i % 2] + i * h[2 + (((i + (i % 2)) % 4) / 2)])
end

for n=1, index do
  local key   = ARGV[1] .. ':' .. n
  local found = true

  -- 0.480453013 = ln(2)^2
  local bits = math.floor((entries * math.log(precision * math.pow(0.5, n))) / -0.480453013)

  -- 0.693147180 = ln(2)
  local k = math.floor(0.693147180 * bits / entries)

  for i=1, k do
    if redis.call('GETBIT', key, b[i] % bits) == 0 then
      found = false
      break
    end
  end

  if found then
    return 1
  end
end

return 0

