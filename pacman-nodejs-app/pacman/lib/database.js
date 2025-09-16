'use strict';

var MongoClient = require('mongodb').MongoClient;
var config = require('./config');
var _db;

function Database() {
    this.connect = function(app, callback) {
        MongoClient.connect(
            config.database.url,
            config.database.options,
            function (err, client) {
                if (err) {
                    console.log(err);
                    console.log(config.database.url);
                    console.log(config.database.options);
                } else {
                    // v3 gives a MongoClient; we must call .db()
                    var dbName = (function () {
                        try {
                            var u = new URL(config.database.url);
                            return (u.pathname && u.pathname !== '/') ? u.pathname.replace(/^\//, '') : 'pacman';
                        } catch (e) {
                            return 'pacman';
                        }
                    })();
                    _db = client.db(dbName);
                    app.locals.db = _db;
                }
                callback(err);
            }
        );
    };

    this.getDb = function(app, callback) {
        if (!_db) {
            this.connect(app, function(err) {
                if (err) {
                    console.log('Failed to connect to database server');
                } else {
                    console.log('Connected to database server successfully');
                }
                callback(err, _db);
            });
        } else {
            callback(null, _db);
        }
    };
}

module.exports = exports = new Database(); // Singleton
