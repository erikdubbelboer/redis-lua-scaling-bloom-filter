
local entries   = ARGV[2]
local precision = ARGV[3]
local hash      = redis.sha1hex(ARGV[4])

-- This uses a variation on:
-- 'Less Hashing, Same Performance: Building a Better Bloom Filter'
-- http://www.eecs.harvard.edu/~kirsch/pubs/bbbf/esa06.pdf
local h = { }
h[0] = tonumber(string.sub(hash, 1 , 8 ), 16)
h[1] = tonumber(string.sub(hash, 9 , 16), 16)
h[2] = tonumber(string.sub(hash, 17, 24), 16)
h[3] = tonumber(string.sub(hash, 25, 32), 16)

for layer=1,32 do
  local key   = ARGV[1] .. ':' .. layer .. ':'
  local index = redis.call('GET', key .. 'count')

  if not index then
    return layer - 1
  end

  index = math.ceil(index / entries)

  -- Based on the math from: http://en.wikipedia.org/wiki/Bloom_filter#Probability_of_false_positives
  -- Combined with: http://www.sciencedirect.com/science/article/pii/S0020019006003127
  -- 0.693147180 = ln(2)
  -- 0.480453013 = ln(2)^2
  local maxk = math.floor(0.693147180 * math.floor((entries * math.log(precision * math.pow(0.5, index))) / -0.480453013) / entries)
  local b    = { }

  for i=1, maxk do
    table.insert(b, h[i % 2] + i * h[2 + (((i + (i % 2)) % 4) / 2)])
  end
    
  local inlayer = false

  for n=1, index do
    local keyn  = key .. n
    local found = true

    -- 0.480453013 = ln(2)^2
    local bits = math.floor((entries * math.log(precision * math.pow(0.5, n))) / -0.480453013)

    -- 0.693147180 = ln(2)
    local k = math.floor(0.693147180 * bits / entries)

    for i=1, k do
      if redis.call('GETBIT', keyn, b[i] % bits) == 0 then
        found = false
        break
      end
    end

    if found then
      inlayer = true
      break
    end
  end

  if inlayer == false then
    return layer - 1
  end
end

return 0

