
redis-lua-scaling-bloom-filter
==============================

`add.lua` and `check.lua` are two lua scripts for a [scaling bloom filter](http://en.wikipedia.org/wiki/Bloom_filter#Scalable_Bloom_filters) for [Redis](http://redis.io/)

The scripts are to be executed using the [EVAL](http://redis.io/commands/eval) command in Redis.

_These scripts will probably not work on Redis cluster since the keys used inside the script aren't all passed as arguments!_

`add.lua`
---------

The `add.lua` script adds a new element to the filter. It will create the filter when it doesn't exist yet.

It expects 4 arguments.

1. The base name of the keys to use.
2. The initial size of the bloom filter (in number of items).
3. The probability of false positives.
4. The element to add to the filter.


For example the following call would add "something" to a filter named test
which will initially be able to hold 10000 elements with a probability of false positives of 1%.

`
eval "add.lua source here" test 10000 0.01 something
`


`check.lua`
-----------

The `check.lua` script check if an element is contained in the bloom filter.

It expects 4 arguments.

1. The base name of the keys to use.
2. The initial size of the bloom filter (in number of items).
3. The probability of false positives.
4. The element to check for.


For example the following call would check if "something" is part of the filter named test
which will initially be able to hold 10000 elements with a probability of false positives of 1%.

`
eval "check.lua source here" test 10000 0.01 something
`


Tests
-----

```
npm install redis
node add.js
node check.js
```

`add.js` will add elements to a filter named test and then check if the elements are part of the filter.

`check.js` will test random elements against the filter build by `add.js` to find the probability of false positives.

Both script assume Redis is running on the default port.


Benchmark
---------

You can run `./benchmark.sh` to see how fast the scripts are.

This script assumes Redis is running on the default port and `redis-cli` and `redis-benchmark` are installed.

This is the output on my Intel Xeon E5620 @ 2.40GHz:
```
====== evalsha ba52b18eddd56dc34113319ca7b4a66244caa623 1 RKvUxAjWkU 1000000 0.01 :rand:000000000000 ======
  200000 requests completed in 10.92 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

34.48% <= 1 milliseconds
99.92% <= 2 milliseconds
99.99% <= 3 milliseconds
100.00% <= 4 milliseconds
18313.34 requests per second

check.lua
====== evalsha ae05a3d2a7106feb7085bccd9fbf34178a686151 1 RKvUxAjWkU 1000000 0.01 :rand:000000000000 ======
  200000 requests completed in 11.37 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

21.13% <= 1 milliseconds
99.83% <= 2 milliseconds
100.00% <= 2 milliseconds
17587.06 requests per second
```

