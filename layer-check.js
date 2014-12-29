
var fs = require('fs');

var redis = require('redis');
var srand = require('srand');


var client = redis.createClient(6379, '127.0.0.1');

var checksource = fs.readFileSync('layer-check.lua', 'ascii');

var entries   = process.argv[2] || 10000;
var precision = process.argv[3] || 0.01;

var checksha = '';

var start;

var count = process.argv[4] || 100000;
var found = [];
var added = 0;


console.log('entries   = ' + entries);
console.log('precision = ' + (precision * 100) + '%');
console.log('count     = ' + count);


srand.seed(2);


function check(n) {
  if (n == count) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    var total = 0;

    for (var i = 1; i < found.length; ++i) {
      total += found[i];

      console.log('layer ' + i + ': ' + (found[i] / (count / 100)) + '% false positives');
    }

    console.log((total / (count / 100)) + '% false positives total');

    console.log('done.');
    process.exit();
    return;
  }

  // Mimic the same number of srand.random() calls as layer-add.js
  // so we get the same id's if we use the same seed.
  while (added > 100 && srand.random() < 0.3) {
    srand.random();
    ++added;
  }
  
  var id = Math.ceil(srand.random() * 4000000000);

  client.evalsha(checksha, 0, 'test', entries, precision, id, function(err, layer) {
    if (err) {
      throw err;
    }

    if (layer) {
      if (found[layer]) {
        found[layer]++;
      } else {
        found[layer] = 1;
      }
    }

    check(n + 1);
  });
}


client.send_command('script', ['load', checksource], function(err, sha) {
  if (err) {
    throw err;
  }

  checksha = sha;

  console.log('checking...');

  start = Date.now();

  check(0);
});

