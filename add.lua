
local entries   = ARGV[2]
local precision = ARGV[3]
local hash      = redis.sha1hex(ARGV[4])
local factor    = math.ceil((entries + redis.call('INCR', ARGV[1] .. ':count')) / entries) 
-- 0.69314718055995 = ln(2)
local index     = math.ceil(math.log(factor) / 0.69314718055995)
local scale     = math.pow(2, index - 1) * entries
local key       = ARGV[1] .. ':' .. index

-- Based on the math from: http://en.wikipedia.org/wiki/Bloom_filter#Probability_of_false_positives
-- Combined with: http://www.sciencedirect.com/science/article/pii/S0020019006003127
-- 0.4804530139182 = ln(2)^2
local bits = math.floor(-(scale * math.log(precision * math.pow(0.5, index))) / 0.4804530139182)

-- 0.69314718055995 = ln(2)
local k = math.floor(0.69314718055995 * bits / scale)

-- This uses a variation on:
-- 'Less Hashing, Same Performance: Building a Better Bloom Filter'
-- http://www.eecs.harvard.edu/~kirsch/pubs/bbbf/esa06.pdf
local h = { }
h[0] = tonumber(string.sub(hash, 1 , 8 ), 16)
h[1] = tonumber(string.sub(hash, 9 , 16), 16)
h[2] = tonumber(string.sub(hash, 17, 24), 16)
h[3] = tonumber(string.sub(hash, 25, 32), 16)

for i=1, k do
  redis.call('SETBIT', key, (h[i % 2] + i * h[2 + (((i + (i % 2)) % 4) / 2)]) % bits, 1)
end

