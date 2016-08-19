
var fs = require('fs');

var redis = require('redis');
var srand = require('srand');


var client = redis.createClient(6379, '127.0.0.1');

var checksource = fs.readFileSync('check.lua', 'ascii');

var entries   = process.argv[2] || 10000;
var precision = process.argv[3] || 0.01;

var checksha = '';

var start;

var count = process.argv[4] || 100000;
var found = 0;


console.log('entries   = ' + entries);
console.log('precision = ' + (precision * 100) + '%');
console.log('count     = ' + count);


srand.seed(2);


function check(n) {
  if (n == count) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    console.log((found / (count / 100)) + '% false positives');

    console.log('done.');
    process.exit();
    return;
  }

  var id = Math.ceil(srand.random() * 4000000000);

  client.evalsha(checksha, 0, 'test', entries, precision, id, function(err, yes) {
    if (err) {
      throw err;
    }

    if (yes) {
      ++found;
    }

    check(n + 1);
  });
}


client.send_command('script', ['load', checksource], function(err, sha) {
  if (err) {
    throw err;
  }

  checksha = sha;

  console.log('adding check function... ' + checksha);

  start = Date.now();

  check(0);
});

