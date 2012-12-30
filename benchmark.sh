#!/bin/sh

# Get the SHA1 hash for our scripts simply be generating an error and
# filtering out the hash.
add=`redis-cli --eval add.lua | sed 's/.*f_\([0-9a-z]\{40\}\).*/\1/'`
check=`redis-cli --eval check.lua | sed 's/.*f_\([0-9a-z]\{40\}\).*/\1/'`

# Find a free key to use.
# 10 characters should be enough to find a free key quickly.
while true; do
  key=`tr -dc "[:alnum:]" < /dev/urandom | head -c 10`

  if [ -z `echo "keys $key:*" | redis-cli --raw` ]; then
    break
  fi
done


args="1 $key 1000000 0.01 :rand:000000000000"
iter=200000

echo add.lua
redis-benchmark -c 20 -n $iter -r 2000000000 evalsha $add $args

echo check.lua
redis-benchmark -c 20 -n $iter -r 2000000000 evalsha $check $args


# Delete all the keys we used.
for k in `echo "keys $key:*" | redis-cli --raw`; do
  echo "del $k" | redis-cli > /dev/null
done

