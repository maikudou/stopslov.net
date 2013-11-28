(function() {
  var Backbone, controller, fs, httpNode, url, _;

  fs = require('fs');

  url = require('url');

  _ = require('underscore');

  Backbone = require('backbone');

  httpNode = require('./httpNode');

  controller = (function() {
    controller.prototype.routes = {
      "/": "home",
      "/api/": "home"
    };

    function controller() {
      _.extend(this, Backbone.Events);
      this._routeToRegexp();
      this.server = new httpNode(4400);
      this.listenTo(this.server, 'ready', function(reqModel) {
        return this.navigate(reqModel);
      });
    }

    controller.prototype.navigate = function(reqModel) {
      var addr, currentRoute, params;
      addr = url.parse(reqModel.get('request').url);
      currentRoute = _.find(this.routesReg, function(route) {
        return route.exp.test(addr.pathname);
      });
      if ((currentRoute != null) && this[currentRoute.method]) {
        params = addr.pathname.match(currentRoute.exp).slice(1);
        params.push(reqModel);
        return this[currentRoute.method].apply(this, params);
      } else {
        return this.page404(reqModel);
      }
    };

    controller.prototype._routeToRegexp = function() {
      var newRoutes, route;
      newRoutes = [];
      for (route in this.routes) {
        newRoutes.push({
          exp: Backbone.Router.prototype._routeToRegExp(route),
          method: this.routes[route]
        });
      }
      return this.routesReg = newRoutes;
    };

    controller.prototype.home = function(model) {
      return this.server.response(model, {
        code: 200,
        body: JSON.stringify(_.map(JSON.parse(model.get('data')), function(obj) {
          return Number(obj) * 2;
        }))
      });
    };

    controller.prototype.page404 = function(model) {
      console.log(arguments);
      return this.server.response(model, {
        code: 200,
        headers: {
          'Content-Type': 'text/html'
        },
        body: '<h1>404 Not found</h1>'
      });
    };

    return controller;

  })();

  new controller();

}).call(this);
