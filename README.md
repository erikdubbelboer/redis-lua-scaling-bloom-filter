
redis-lua-scaling-bloom-filter
==============================

`add.lua`, `cas.lua` and `check.lua` are three lua scripts for a [scaling bloom filter](http://en.wikipedia.org/wiki/Bloom_filter#Scalable_Bloom_filters) for [Redis](http://redis.io/)

`layer-add.lua` and `later-check.lua` are two lua scripts for a [scaling layered bloom filter](https://en.wikipedia.org/wiki/Bloom_filter#Layered_Bloom_filters) for [Redis](http://redis.io/)

The scripts are to be executed using the [EVAL](http://redis.io/commands/eval) command in Redis.

_These scripts will probably not work on Redis cluster since the keys used inside the script aren't all passed as arguments!_

The layered filter has a maximum number of 32 layers. You can modify this in the source.


`add.lua`, `cas.lua` and `layer-add.lua`
----------------------------------------

The `add.lua` script adds a new element to the filter. It will create the filter when it doesn't exist yet.

`cas.lua` does a Check And Set, this will not add the element if it doesn't already exist.
`cas.lua` will return 1 if the element is added, 0 otherwise.
Since we use a scaling filter adding an element using `add.lua` might cause the element
to exist in multiple parts of the filter at the same time. `cas.lua` prevents this.
Using only `cas.lua` the `:count` key of the filter will accurately count the number of elements added to the filter.
Only using `cas.lua` will also lower the number of false positives by a small amount (less duplicates in the filter means less bits set).

`layer-add.lua` does a similar thing to `cas.lua` since this is necessary for the layer part to work
(need to check all the filters in a layer to see if it already exists in the layer).
`layer-add.lua` will return the layer number the element was added to.

These scripts expects 4 arguments.

1. The base name of the keys to use.
2. The initial size of the bloom filter (in number of elements).
3. The probability of false positives.
4. The element to add to the filter.


For example the following call would add "something" to a filter named test
which will initially be able to hold 10000 elements with a probability of false positives of 1%.

`
eval "add.lua source here" 0 test 10000 0.01 something
`


`check.lua` and `layer-check.lua`
---------------------------------

The `check.lua` and `layer-check.lua` scripts check if an element is contained in the bloom filter.

`layer-check.lua` returns the layer the element was found in.

These scripts expects 4 arguments.

1. The base name of the keys to use.
2. The initial size of the bloom filter (in number of elements).
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

This is the outputs on my 2.3GHz 2012 MacBook Pro Retina:
```
add.lua
====== evalsha ab31647b3931a68b3b93a7354a297ed273349d39 0 HSwVBmHECt 1000000 0.01 :rand:000000000000 ======
  200000 requests completed in 8.27 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

94.57% <= 1 milliseconds
100.00% <= 2 milliseconds
24175.03 requests per second


check.lua
====== evalsha 437a3b0c6a452b5f7a1f10487974c002d41f4a04 0 HSwVBmHECt 1000000 0.01 :rand:000000000000 ======
  200000 requests completed in 8.54 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

92.52% <= 1 milliseconds
100.00% <= 8 milliseconds
23419.20 requests per second


layer-add.lua
====== evalsha 7ae29948e3096dd064c22fcd8b628a5c77394b0c 0 ooPb5enskU 1000000 0.01 :rand:000000000000 ======
  20000 requests completed in 12.61 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

55.53% <= 12 milliseconds
75.42% <= 13 milliseconds
83.71% <= 14 milliseconds
91.48% <= 15 milliseconds
97.76% <= 16 milliseconds
99.90% <= 24 milliseconds
100.00% <= 24 milliseconds
1586.04 requests per second


layer-check.lua
====== evalsha c1386438944daedfc4b5c06f79eadb6a83d4b4ea 0 ooPb5enskU 1000000 0.01 :rand:000000000000 ======
  20000 requests completed in 11.13 seconds
  20 parallel clients
  3 bytes payload
  keep alive: 1

0.00% <= 9 milliseconds
74.12% <= 11 milliseconds
80.43% <= 12 milliseconds
83.93% <= 13 milliseconds
97.43% <= 14 milliseconds
99.89% <= 15 milliseconds
100.00% <= 15 milliseconds
1797.59 requests per second
```

