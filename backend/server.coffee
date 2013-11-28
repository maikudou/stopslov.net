fs          = require 'fs'
url         = require 'url'
_           = require 'underscore'
Backbone    = require 'backbone'
httpNode    = require './httpNode'



class controller
    routes:
        "/": "home"
        "/api/": "home"

    constructor: ->
        _.extend @, Backbone.Events
        @_routeToRegexp()

        @server = new httpNode(4400)
        @listenTo @server, 'ready', (reqModel)->
            @navigate reqModel

    navigate: (reqModel)->
        addr = url.parse(reqModel.get('request').url)

        currentRoute = _.find @routesReg, (route)->
            return route.exp.test addr.pathname

        if currentRoute? and @[currentRoute.method]
            params = addr.pathname.match(currentRoute.exp).slice(1)
            params.push reqModel
            @[currentRoute.method].apply @, params

        else
            @page404 reqModel

    _routeToRegexp: ->
        newRoutes = []
        for route of @routes
            newRoutes.push
                exp: Backbone.Router.prototype._routeToRegExp(route)
                method: @routes[route]

        @routesReg = newRoutes

    home: (model)->
        @server.response model,
            code: 200,
            body: JSON.stringify _.map JSON.parse(model.get('data')), (obj)->
                return Number(obj)*2

    page404: (model)->
        console.log arguments
        @server.response model,
            code: 200,
            headers:
                'Content-Type': 'text/html'

            body: '<h1>404 Not found</h1>'


new controller()