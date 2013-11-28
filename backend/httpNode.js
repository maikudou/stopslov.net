(function() {
  var Backbone, Request, Requests, http, httpNode, _;

  http = require('http');

  _ = require('underscore');

  Backbone = require('backbone');

  Request = Backbone.Model.extend({
    initialize: function() {
      return this.prepareRequest();
    },
    prepareRequest: function() {
      var _this = this;
      switch (this.get('request').method) {
        case 'POST':
        case 'PUT':
        case 'DELETE':
          return this.loadData(function() {
            return _this.setReadyState();
          });
        case 'OPTIONS':
          return this.onSendEmpty();
        default:
          return this.setReadyState();
      }
    },
    loadData: function(callback) {
      var data,
        _this = this;
      data = '';
      this.get('request').addListener("data", function(chunk) {
        return data += chunk.toString();
      });
      return this.get('request').addListener("end", function() {
        _this.set('data', data);
        return callback.apply();
      });
    },
    getCrossDomainJSONHeaders: function() {
      return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'origin, authorization, content-type, accept',
        'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE',
        'Content-Type': 'application/json; charset=utf-8'
      };
    },
    setReadyState: function() {
      this.set('ready', true);
      return this.trigger('ready', this);
    },
    onSendEmpty: function(callback) {
      if (typeof callback === 'function') {
        if (this.get('sendEmpty')) {
          return callback();
        } else {
          return this.on('sendEmpty', function() {
            return callback();
          });
        }
      } else {
        this.set('sendEmpty', true);
        return this.trigger('sendEmpty');
      }
    }
  });

  Requests = Backbone.Collection.extend({
    model: Request,
    initialize: function() {
      return this.on('add', function(model) {
        var _this = this;
        return model.onSendEmpty(function() {
          return _this.response(model, {
            code: 200
          });
        });
      });
    },
    response: function(model, params) {
      var response;
      if (params == null) {
        params = {};
      }
      response = model.get('response');
      if (params.code) {
        if (!params.headers) {
          params.headers = {};
        }
        response.writeHead(params.code, _.defaults(params.headers, model.getCrossDomainJSONHeaders()));
      }
      if (params.body) {
        response.write(params.body);
      }
      response.end();
      return this.remove(model);
    }
  });

  httpNode = (function() {
    function httpNode(port) {
      if (port == null) {
        port = 8000;
      }
      this.requestCollection = new Requests();
      this.server = http.createServer(_.bind(this.request, this));
      this.server.listen(port);
      return this.requestCollection;
    }

    httpNode.prototype.request = function(req, res) {
      return this.requestCollection.add({
        request: req,
        response: res,
        timestamp: new Date()
      });
    };

    httpNode.prototype.getPostData = function(reqest, callback) {
      var data;
      data = '';
      reqest.addListener("data", function(chunk) {
        return data += chunk.toString();
      });
      return reqest.addListener("end", function() {
        return callback(data);
      });
    };

    return httpNode;

  })();

  module.exports = httpNode;

}).call(this);
