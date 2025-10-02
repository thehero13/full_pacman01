var express = require('express');
var router = express.Router();
var bodyParser = require('body-parser');
var Database = require('../lib/database');
const opentelemetry = require('@opentelemetry/api'); // OpenTelemetry API

// ---- Single metric instrument (Counter) ----
// Requires a MeterProvider to be initialized at app start (via your metrics.js preload)
const meter = opentelemetry.metrics.getMeter('pacman', '1.0.0');

// One simple metric: add the raw score value each submission
const hsScore = meter.createCounter('pacman.highscore.score', {
  unit: '{points}',
  description: 'High score submissions (adds raw score value per submission)',
});

// Helper: build metric attributes from the request (keep cardinality reasonable)
function hsAttrs(req, userLevel) {
  return {
    name: String(req.body.name || ''),
    cloud: String(req.body.cloud || ''),
    zone: String(req.body.zone || ''),
    host: String(req.body.host || req.hostname || ''),
    level: Number(isNaN(userLevel) ? 0 : userLevel),
    // If needed, you can add more attributes, but mind cardinality:
    // referer: String(req.headers.referer || ''),
    // user_agent: String(req.headers['user-agent'] || ''),
  };
}

// create application/x-www-form-urlencoded parser
var urlencodedParser = bodyParser.urlencoded({ extended: false });

// middleware that is specific to this router
router.use(function timeLog(req, res, next) {
  console.log('Time: ', Date());
  next();
});

router.get('/list', urlencodedParser, function (req, res, next) {
  console.log('[GET /highscores/list]');
  Database.getDb(req.app, function (err, db) {
    if (err) {
      return next(err);
    }

    // Retrieve the top 10 high scores
    var col = db.collection('highscore');
    col.find({}).sort([['score', -1]]).limit(10).toArray(function (err, docs) {
      var result = [];
      if (err) {
        console.log(err);
      }

      docs.forEach(function (item) {
        result.push({
          name: item['name'],
          cloud: item['cloud'],
          zone: item['zone'],
          host: item['host'],
          score: item['score'],
        });
      });

      res.json(result);
    });
  });
});

// Accessed at /highscores
router.post('/', urlencodedParser, function (req, res, next) {
  console.log(
    '[POST /highscores] body =',
    req.body,
    ' host =',
    req.headers.host,
    ' user-agent =',
    req.headers['user-agent'],
    ' referer =',
    req.headers.referer
  );

  var userScore = parseInt(req.body.score, 10),
    userLevel = parseInt(req.body.level, 10);

  // Add custom span attributes (auto-instrumentation creates the span)
  const span = opentelemetry.trace.getActiveSpan();
  if (span) {
    span.setAttribute('player.name', req.body.name || '');
    span.setAttribute('player.highscore', isNaN(userScore) ? 0 : userScore);
  }

  // Emit the single metric (Counter) with the raw score value
  if (!isNaN(userScore)) {
    const attrs = hsAttrs(req, userLevel);
    hsScore.add(userScore, attrs);
    if (process.env.METRICS_DEBUG === '1') {
      console.log(
        '[metrics] pacman.highscore.score+=%s name=%s zone=%s host=%s level=%s',
        userScore,
        attrs.name,
        attrs.zone,
        attrs.host,
        attrs.level
      );
    }
  }

  Database.getDb(req.app, function (err, db) {
    if (err) {
      return next(err);
    }

    // Insert high score with extra user data
    db.collection('highscore').insertOne(
      {
        name: req.body.name,
        cloud: req.body.cloud,
        zone: req.body.zone,
        host: req.body.host,
        score: userScore,
        level: userLevel,
        date: Date(),
        referer: req.headers.referer,
        user_agent: req.headers['user-agent'],
        hostname: req.hostname,
        ip_addr: req.ip,
      },
      {
        w: 'majority',
        j: true,
        wtimeout: 10000,
      },
      function (err) {
        var returnStatus = '';

        if (err) {
          console.log(err);
          returnStatus = 'error';
        } else {
          console.log('Successfully inserted highscore');
          returnStatus = 'success';
        }

        res.json({
          name: req.body.name,
          zone: req.body.zone,
          score: userScore,
          level: userLevel,
          rs: returnStatus,
        });
      }
    );
  });
});

module.exports = router;

