http = require 'http'
_           = require 'underscore'
Backbone    = require 'backbone'

Request = Backbone.Model.extend
    initialize: ->
        @prepareRequest()

    prepareRequest: ->
        switch @get('request').method
            when 'POST', 'PUT', 'DELETE'
                @loadData =>
                    @setReadyState()

            when 'OPTIONS'
                @onSendEmpty()

            else
                @setReadyState()

    loadData: (callback)->
        data = ''
        @get('request').addListener "data", (chunk)->
            data += chunk.toString()

        @get('request').addListener "end", =>
            @set 'data', data
            callback.apply()

    getCrossDomainJSONHeaders: ->
        return {
            'Access-Control-Allow-Origin': '*'
            'Access-Control-Allow-Headers': 'origin, authorization, content-type, accept'
            'Access-Control-Allow-Methods': 'POST, GET, OPTIONS, PUT, DELETE'
            'Content-Type': 'application/json; charset=utf-8'
        }

    setReadyState: ->
        @set('ready', true)
        @trigger 'ready', @

    onSendEmpty: (callback)->
        if typeof callback is 'function'
            if @get 'sendEmpty'
                callback()

            else
                @on 'sendEmpty', ->
                    callback()

        else
            @set('sendEmpty', true)
            @trigger 'sendEmpty'

Requests = Backbone.Collection.extend
    model: Request

    initialize: ->
        @on 'add', (model)->
            #Ставим таймаут в пол-минуты
            model.set 'timeout', setTimeout =>
                @response model,
                    code: 502
                    body: '{"success": false, "error": 502}'

            , 30000

            model.onSendEmpty =>
                @response model, {code: 200}

    response: (model, params={})->
        clearTimeout model.get 'timeout'
        response = model.get 'response'

        if params.code
            params.headers = {} unless params.headers
            response.writeHead params.code, _.defaults( params.headers, model.getCrossDomainJSONHeaders() )

        if params.body
            response.write params.body

        #Отправляем модель, в конце удаляем запрос
        response.end()
        @remove model

class httpNode
    constructor: (port=8000)->
        @requestCollection = new Requests()
        @server = http.createServer _.bind(@request, @)

        @server.listen port

        return @requestCollection

    request: (req, res)->
        @requestCollection.add
            request: req
            response: res
            timestamp: new Date()

    getPostData: (reqest, callback)->
        data = ''
        reqest.addListener "data", (chunk)->
            data += chunk.toString()

        reqest.addListener "end", ->
            callback data

module.exports = httpNode