
var fs = require('fs');

var redis = require('redis');


var client = redis.createClient(6379, '127.0.0.1');

var cassource   = fs.readFileSync('cas.lua', 'ascii');
var checksource = fs.readFileSync('check.lua', 'ascii');

var entries   = process.argv[2] || 10000;
var precision = process.argv[3] || 0.01;

var cassha   = '';
var checksha = '';

var start;

var count = process.argv[4] || 100000;
var added = [];
var found = 0;


console.log('entries   = ' + entries);
console.log('precision = ' + precision);
console.log('count     = ' + count);


function check(n) {
  if (n == count) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    console.log('done.');
    process.exit();
    return;
  }

  client.evalsha(checksha, 0, 'test', entries, precision, added[n], function(err, yes) {
    if (err) {
      throw err;
    }

    if (!yes) {
      console.log(added[n] + ' was not found!');
    }

    check(n + 1);
  });
}


function cas(n) {
  if (n == count) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    console.log((found / (count / 100)) + '% false positives');

    console.log('checking...');
    
    start = Date.now();

    check(0);
    return;
  }

  var id = Math.round(Math.random() * 4000000000);

  added.push(id);

  client.evalsha(cassha, 0, 'test', entries, precision, id, function(err, yes) {
    if (err) {
      throw err;
    }

    if (yes) {
      ++found;
    }

    cas(n + 1);
  });
}


function load() {
  client.send_command('script', ['load', cassource], function(err, sha) {
    if (err) {
      throw err;
    }

    cassha = sha;

    client.send_command('script', ['load', checksource], function(err, sha) {
      if (err) {
        throw err;
      }

      checksha = sha;

      console.log('casing...');

      start = Date.now();

      cas(0);
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

