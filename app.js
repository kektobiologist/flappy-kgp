var express = require('express');
var app = express();
var mongojs = require('mongojs');
var db = mongojs('localhost/test');
var flappy = db.collection('flappy')
app.use(express.static('.'));

var bodyParser = require('body-parser');
app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // support encoded bodies

app.listen(3000, function () {
  console.log('Example app listening on port 3000!');
});

var lb = []

app.get('/getLeaderboard', function (req, res) {
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


app.post('/sendScore', function (req, res) {
  // we will get all scores
  key = req.body.key
  // add every score to db. good for analysis later on.
  // on 2nd thought, don't. heroku might explode.
  hiscore = 0
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
  })
  
  res.send('OK');
});