
local entries   = ARGV[2]
local precision = ARGV[3]
local hash      = redis.sha1hex(ARGV[4])

-- This uses a variation on:
-- 'Less Hashing, Same Performance: Building a Better Bloom Filter'
-- https://www.eecs.harvard.edu/~michaelm/postscripts/tr-02-05.pdf
local h = { }
h[0] = tonumber(string.sub(hash, 1 , 8 ), 16)
h[1] = tonumber(string.sub(hash, 9 , 16), 16)
h[2] = tonumber(string.sub(hash, 17, 24), 16)
h[3] = tonumber(string.sub(hash, 25, 32), 16)

for layer=1,32 do
  local key   = ARGV[1] .. ':' .. layer .. ':'
  local count = redis.call('GET', key .. 'count')

  if not count then
    return layer - 1
  end

  local factor = math.ceil((entries + count) / entries)
  -- 0.69314718055995 = ln(2)
  local index  = math.ceil(math.log(factor) / 0.69314718055995)
  local scale  = math.pow(2, index - 1) * entries

  -- Based on the math from: http://en.wikipedia.org/wiki/Bloom_filter#Probability_of_false_positives
  -- Combined with: http://www.sciencedirect.com/science/article/pii/S0020019006003127
  -- 0.4804530139182 = ln(2)^2
  local maxbits = math.floor((scale * math.log(precision * math.pow(0.5, index))) / -0.4804530139182)

  -- 0.69314718055995 = ln(2)
  local maxk = math.floor(0.69314718055995 * maxbits / scale)
  local b    = { }

  for i=1, maxk do
    table.insert(b, h[i % 2] + i * h[2 + (((i + (i % 2)) % 4) / 2)])
  end

  local inlayer = false

  for n=1, index do
    local keyn   = key .. n
    local found  = true
    local scalen = math.pow(2, n - 1) * entries

    -- 0.4804530139182 = ln(2)^2
    local bits = math.floor((scalen * math.log(precision * math.pow(0.5, n))) / -0.4804530139182)

    -- 0.69314718055995 = ln(2)
    local k = math.floor(0.69314718055995 * bits / scalen)

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

return 32

