var express = require('express');
var app = express();
var mongojs = require('mongojs');
var db = mongojs('mongodb://flappy:flappy@ds023674.mlab.com:23674/heroku_j1s0h387');
var flappy = db.collection('flappy')
var flappyHall = db.collection('flappyHall')

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
  // console.log("good token.");
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
  })
  res.send('OK');
});