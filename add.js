
var fs = require('fs');

var redis = require('redis');


var client = redis.createClient(6379, '127.0.0.1');

var addsource   = fs.readFileSync('add.lua', 'ascii');
var checksource = fs.readFileSync('check.lua', 'ascii');

var entries   = 10000;
var precision = 0.01;

var addsha   = '';
var checksha = '';

var start;

var count = 10000;
var added = [];


function check(n) {
  if (n == count) {
    var sec = count / ((Date.now() - start) / 1000);
    console.log(sec + ' per second');

    console.log('done.');
    process.exit();
    return;
  }

  client.evalsha(checksha, 1, 'test', entries, precision, added[n], function(err, found) {
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

  var id = Math.round(Math.random() * 4000000000);

  added.push(id);

  client.evalsha(addsha, 1, 'test', entries, precision, id, function(err) {
    if (err) {
      throw err;
    }

    add(n + 1);
  });
}


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

