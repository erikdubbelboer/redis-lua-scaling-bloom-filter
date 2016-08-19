
var fs = require('fs');

var redis = require('redis');
var srand = require('srand');


var client = redis.createClient(6379, '127.0.0.1');

var addsource   = fs.readFileSync('layer-add.lua', 'ascii');
var checksource = fs.readFileSync('layer-check.lua', 'ascii');

var entries   = process.argv[2] || 10000;
var precision = process.argv[3] || 0.01;

var addsha   = '';
var checksha = '';

var start;

var count = process.argv[4] || 100000;
var added = [];
var addto = [];
var wrong = 0;


console.log('entries   = ' + entries);
console.log('precision = ' + (precision * 100) + '%');
console.log('count     = ' + count);


srand.seed(1);


function check(n) {
  if (n == added.length) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    console.log((wrong / (count / 100)) + '% in a too high layer');

    console.log('done.');
    process.exit();
    return;
  }

  client.evalsha(checksha, 0, 'test', entries, precision, added[n][0], function(err, found) {
    if (err) {
      throw err;
    }

    var layer = added[n][1];

    if (found != layer) {
      // Finding one in a too low layer means it wasn't added to the higher layer!
      if (found < layer) {
        console.log(added[n][0] + ' expected in ' + layer + ' found in ' + found + '!');
      }

      ++wrong;
    }

    check(n + 1);
  });
}


function add(n) {
  if (n == count) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    // This will never print 100% for layer 1 since false positives will
    // make some new items be added to higher layers right away.
    for (var i = 1; i < addto.length; ++i) {
      console.log('layer ' + i + ': ' + addto[i] + ' (' + (addto[i] / (count / 100)) + '%) added');
    }

    console.log('checking...');

    start = Date.now();

    check(0);
    return;
  }

  var i = 0;

  // 30% of the time we add an item we already know,
  // pushing it up one layer.
  if (added.length > 100 && srand.random() < 0.3) {
    i = Math.floor(srand.random()*added.length);
  } else {
    var id = Math.ceil(srand.random() * 4000000000);

    i = added.push([id, 0]) - 1;
  }

  client.evalsha(addsha, 0, 'test', entries, precision, added[i][0], function(err, layer) {
    if (err) {
      throw err;
    }

    if (layer == 0) {
      throw new Error('We have run out of layers!');
    } else {
      if (addto[layer]) {
        addto[layer]++;
      } else {
        addto[layer] = 1;
      }
    }

    added[i][1]++;

    add(n + 1);
  });
}


function load() {
  client.send_command('script', ['load', addsource], function(err, sha) {
    if (err) {
      throw err;
    }

    addsha = sha;
    console.log('adding add function... ' + addsha);

    client.send_command('script', ['load', checksource], function(err, sha) {
      if (err) {
        throw err;
      }

      checksha = sha;

      console.log('adding check function... ' + checksha);

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

