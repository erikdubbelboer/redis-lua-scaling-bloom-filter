
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
  local key      = ARGV[1] .. ':' .. layer .. ':'
  local countkey = key .. 'count'
  local count    = redis.call('GET', countkey)
  if not count then
    count = 1
  else
    count = count + 1
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
  
  -- Only do this if we have data already.
  if index > 1 then
    -- The last fiter will be handled below.
    for n=1, index-1 do
      local keyn   = key .. n
      local scalen = math.pow(2, n - 1) * entries
      
      -- 0.4804530139182 = ln(2)^2
      local bits = math.floor((scalen * math.log(precision * math.pow(0.5, n))) / -0.4804530139182)
      
      -- 0.69314718055995 = ln(2)
      local k = math.floor(0.69314718055995 * bits / scalen)
      
      local found = true
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
  end
  
  if inlayer == false then
    key = key .. index
    
    local found = true
    for i=1, maxk do
      if redis.call('SETBIT', key, (h[i % 2] + i * h[2 + (((i + (i % 2)) % 4) / 2)]) % maxbits, 1) == 0 then
        found = false
      end
    end
    
    -- If it wasn't found in this layer break
    if found == false then
      -- INCR is a little bit faster than SET.
      redis.call('INCR', countkey)
      return layer
    end
  end
end

-- We only reach this is we ran out of layers
return 0
