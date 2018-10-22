
var fs = require('fs');

var redis = require('redis');
var srand = require('srand');


var client = redis.createClient(6379, '127.0.0.1');

var addsource   = fs.readFileSync('add.lua', 'ascii');
var checksource = fs.readFileSync('check.lua', 'ascii');

var entries   = process.argv[2] || 10000;
var precision = process.argv[3] || 0.01;

var addsha   = '';
var checksha = '';

var start;

var count = process.argv[4] || 100000;
var added = [];


console.log('entries   = ' + entries);
console.log('precision = ' + (precision * 100) + '%');
console.log('count     = ' + count);


srand.seed(1);


function randomstring(length) {
  var dict = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ`1234567890-=~!@#$%^&*()_+[]{};:",./<>?';
  var r    = '';
  for (var i = 0; i < length; i++) {
    r += dict[Math.floor(srand.random() * dict.length)];
  }
  return r;
}


function check(n) {
  if (n == count) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    console.log('done.');
    process.exit();
    return;
  }

  client.evalsha(checksha, 0, 'test', entries, precision, added[n], function(err, found) {
    if (err) {
      throw err;
    }

    if (!found) {
      console.log(added[n] + ' was not found!');
    }

    check(n + 1);
  });
}


function add(n) {
  if (n == count) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    console.log('checking...');

    start = Date.now();

    check(0);
    return;
  }

  var id = randomstring(10);

  added.push(id);

  client.evalsha(addsha, 0, 'test', entries, precision, id, function(err) {
    if (err) {
      throw err;
    }

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

