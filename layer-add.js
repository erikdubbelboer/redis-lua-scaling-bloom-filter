
var fs = require('fs');

var redis = require('redis');


var client = redis.createClient(6379, '127.0.0.1');

var addsource   = fs.readFileSync('layer-add.lua', 'ascii');
var checksource = fs.readFileSync('layer-check.lua', 'ascii');

var entries   = process.argv[2] || 10000;
var precision = process.argv[3] || 0.01;
var layers    = process.argv[5] || 10;

var addsha   = '';
var checksha = '';

var start;

var count     = process.argv[4] || 100000;
var added     = [];
var wrong     = 0;
var layersize = count / layers;


console.log('entries   = ' + entries);
console.log('precision = ' + precision);
console.log('count     = ' + count);
console.log('layers    = ' + layers);


function check(n) {
  if (n == count) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');
      
    console.log((wrong / (count / 100)) + '% in wrong layer');

    console.log('done.');
    process.exit();
    return;
  }

  client.evalsha(checksha, 0, 'test', entries, precision, added[n], function(err, found) {
    if (err) {
      throw err;
    }

    var layer = 1 + Math.floor(n / layersize);

    if (found != layer) {
      //console.log(added[n] + ' expected in ' + layer + ' found in ' + found + '!');
      ++wrong;
    }

    check(n + 1);
  });
}


function add(n, layer, id) {
  if (n == count) {
    var sec = (count * (layers / 2)) / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    console.log('checking...');
    
    start = Date.now();

    check(0);
    return;
  }

  if (!id) {
    id = Math.round(Math.random() * 4000000000);

    added.push(id);
  }

  if (!layer) {
    layer = 1 + Math.floor(n / layersize);
  }

  client.evalsha(addsha, 0, 'test', entries, precision, id, function(err) {
    if (err) {
      throw err;
    }

    if (layer == 1) {
      add(n + 1);
    } else {
      add(n, layer - 1, id)
    }
  });
}


function load() {
  client.send_command('script', ['load', addsource], function(err, sha) {
    if (err) {
      throw err;
    }

    addsha = sha;

    client.send_command('script', ['load', checksource], function(err, sha) {
      if (err) {
        throw err;
      }

      checksha = sha;

      console.log('adding...');

      start = Date.now();

      add(0);
    });
  });
}


client.keys('test:*', function(err, keys) {
  if (err) {
    throw err;
  }

  console.log('clearing...');

  function clear(i) {
    if (i == keys.length) {
      load();
      return;
    }

    client.del(keys[i], function(err) {
      if (err) {
        throw err;
      }

      clear(i + 1);
    });
  }

  clear(0);
});

