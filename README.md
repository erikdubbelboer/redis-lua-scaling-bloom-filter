
redis-lua-scaling-bloom-filter
==============================

`add.lua` and `check.lua` are two lua scripts for a [scaling bloom filter](http://en.wikipedia.org/wiki/Bloom_filter#Scalable_Bloom_filters) for [Redis](http://redis.io/)

`layer-add.lua` and `later-check.lua` are two lua scripts for a [scaling layered bloom filter](https://en.wikipedia.org/wiki/Bloom_filter#Layered_Bloom_filters) for [Redis](http://redis.io/)

The scripts are to be executed using the [EVAL](http://redis.io/commands/eval) command in Redis.

_These scripts will probably not work on Redis cluster since the keys used inside the script aren't all passed as arguments!_

The layered filter has a maximum number of 32 layers. You can modify this in the source.


`add.lua` and `layer-add.lua`
-----------------------------

The `add.lua` script adds a new element to the filter. It will create the filter when it doesn't exist yet.

It expects 4 arguments.

1. The base name of the keys to use.
2. The initial size of the bloom filter (in number of items).
3. The probability of false positives.
4. The element to add to the filter.


For example the following call would add "something" to a filter named test
which will initially be able to hold 10000 elements with a probability of false positives of 1%.

`
eval "add.lua source here" 0 test 10000 0.01 something
`


`check.lua` and `layer-check.lua`
---------------------------------

The `check.lua` script check if an element is contained in the bloom filter.

It expects 4 arguments.

1. The base name of the keys to use.
2. The initial size of the bloom filter (in number of items).
3. The probability of false positives.
4. The element to check for.


For example the following call would check if "something" is part of the filter named test
which will initially be able to hold 10000 elements with a probability of false positives of 1%.

`
eval "check.lua source here" 0 test 10000 0.01 something
`


Tests
-----

```
$ npm install redis
$ node add.js
$ node check.js
$ # or/and
$ node layer-add.js
$ node layer-check.js
```

`add.js` and `layer-add.js` will add elements to a filter named test and then check if the elements are part of the filter.

`check.js` and `layer-check.js` will test random elements against the filter build by `add.js` or `layer-add.js` to find the probability of false positives.

Both script assume Redis is running on the default port.


Benchmark
---------

You can run `./benchmark.sh` and `./layer-benchmark.sh` to see how fast the scripts are.

This script assumes Redis is running on the default port and `redis-cli` and `redis-benchmark` are installed.

This is the output on my 2.0GHz server:
```
add.lua
====== evalsha 4cfd53f462357c9f9b447d5cb65a70921ad7b288 0 DDLLmog7z8 1000000 0.01 :rand:000000000000 ======
  200000 requests completed in 18.10 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

1.00% <= 1 milliseconds
75.33% <= 2 milliseconds
93.89% <= 3 milliseconds
98.62% <= 4 milliseconds
100.00% <= 16 milliseconds
11048.50 requests per second


check.lua
====== evalsha 279aa74a8937e48a62f0caf9a39daef4e8161fe1 0 DDLLmog7z8 1000000 0.01 :rand:000000000000 ======
  200000 requests completed in 15.02 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

4.05% <= 1 milliseconds
88.81% <= 2 milliseconds
96.79% <= 3 milliseconds
99.34% <= 4 milliseconds
100.00% <= 27 milliseconds
13314.69 requests per second


layer-add.lua
====== evalsha e9bd911b897849625e253ca6bf36ef02379e2c17 0 WUeW9QPaGL 1000000 0.01 :rand:000000000000 ======
  200000 requests completed in 39.83 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

30.97% <= 1 milliseconds
77.07% <= 2 milliseconds
89.23% <= 19 milliseconds
94.54% <= 20 milliseconds
98.94% <= 32 milliseconds
100.00% <= 87 milliseconds
5020.71 requests per second


layer-check.lua
====== evalsha 5122b34c07dacf1d3c8d9328c82b6cd457bc89f3 0 WUeW9QPaGL 1000000 0.01 :rand:000000000000 ======
  200000 requests completed in 208.87 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

0.01% <= 7 milliseconds
94.77% <= 34 milliseconds
98.34% <= 44 milliseconds
98.95% <= 45 milliseconds
100.00% <= 85 milliseconds
957.56 requests per second
```

