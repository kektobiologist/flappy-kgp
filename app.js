var express = require('express');
var app = express();
var mongojs = require('mongojs');
var db = mongojs(process.env.MONGODB_URI || 'test');
var flappy = db.collection('flappy')
var flappyHall = db.collection('flappyHall')
var allGames = db.collection('allGames')
var gameTS = db.collection('gameTS')
var knownHackers = db.collection('knownHackers')

app.use(express.static(__dirname));

var port = process.env.PORT || 3000;

var bodyParser = require('body-parser');
app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies

app.listen(port, function () {
  console.log('Example app listening on port 3000!');
});

var lb = []

app.get('/getLeaderboardSolo', function (req, res) {
  // lets just do a query everytime, doesn't really hurt
  flappy.find().sort({'score': -1}).limit(6, function(err, docs) {
    if (err) {
      console.log(err)
      res.send([])
    }
    else
      res.send(docs);
  })  
});

app.get('/getLeader', function (req, res) {
  flappyHall.find().sort({'score': -1}).limit(1, function(err, docs) {
    if (err) {
      console.log(err)
      res.send([])
    }
    else
      res.send(docs)
  })
});

app.get('/getLeaderboardHall', function (req, res) {
  // lets just do a query everytime, doesn't really hurt
  flappyHall.find().sort({'score': -1}).limit(6, function(err, docs) {
    if (err) {
      console.log(err)
      res.send([])
    }
    else
      res.send(docs);
  });

});

app.get('/getPersonalScores/:browserKey', function (req, res) {
  // lets just do a query everytime, doesn't really hurt
  allGames.find({'browserKey': req.params.browserKey}).sort({'score': -1}).limit(6, function(err, docs) {
    if (err) {
      console.log(err)
      res.send([])
    }
    else
      res.send(docs);
  });

});

String.prototype.hashCode = function() {
  var hash = 0, i, chr, len;
  if (this.length === 0) return hash;
  for (i = 0, len = this.length; i < len; i++) {
    chr   = this.charCodeAt(i);
    hash  = ((hash << 5) - hash) + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
};

app.post('/initGame', function(req, res) {
  key = req.body.key
  gameTS.update(
  {'key': key},
  {'$set': {
    'date': new Date()
  }},
  {'upsert': true}
  )
  res.send('OK');
})

app.post('/sendScore', function (req, res) {
  // we will get all scores
  key = req.body.key
  // add every score to db. good for analysis later on.
  // on 2nd thought, don't. heroku might explode.
  hiscore = 0
  // check if indeed a good token
  token = (req.body.score + key + 'flappy' + req.body.score).hashCode()
  if (req.body.token != token  ) {
    console.log("error! expected " + token + ", got " + req.body.token);
    res.send('OK');
    return;
  }
  // check if we have a gameTS, if not then all good :/
  gameTS.findOne({'key': key}, function(err, result) {
    // console.log("good token.");
    if (result != null) {
      score = parseInt(req.body.score);
      diff = new Date() - result.date
      expected = score * 1200
      console.log('expected ' + expected + ', got ' + diff)
      if (diff < expected) {
        console.log('someone is hacking!')
        knownHackers.insert({'key': key, 'name': req.body.name, 'attemptedScore': score})
        res.send('OK');
        return;
      }
    } else {
      res.send('OK')
      return;
    }
    flappy.findOne({'key': key}, function (err, result) {
      if (result != null) {
        hiscore = result['score']
      }
      console.log('got the result. maybe add?')
      score = parseInt(req.body.score)

      if (score > hiscore) {
        name = req.body.name
        if (!name)
          name = "<noname>"
        flappy.update(
          {'key': key},
          {'$set': {
            'name': name,
            'hall': req.body.hall,
            'score': score
          }},
          {'upsert': true}
        )
      }
      // add to flappyHall collection also
      flappyHall.update(
        {'hall': req.body.hall},
        {'$inc': {'score': score}},
        {'upsert': true}
      )
      // also just add each and every game in a separate collection
      allGames.insert({
        'name': req.body.name,
        'hall': req.body.hall,
        'score': score,
        'key': key,
        'browserKey': req.body.browserKey
      });
    })
    res.send('OK');
  })
});