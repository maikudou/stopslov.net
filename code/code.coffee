window.SSN = {}
window.app = {}

SSN.App = Backbone.Model.extend
    defaults: 
        stopWords: window.SSNWords
        regexp: //

    initialize: ->
        @form = new SSN.Form()
        @output = new SSN.Output()

        @buildRegexp()

        @listenTo @form, 'change:content', @processContent


    buildRegexp: ->
        regexp = '(\\s?'+_.map(@get('stopWords'), (word)->
            return word.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/gi, "\\$&");
        ).join('\\s|\\s?')+'\\s)'

        @set 'regexp', new RegExp(regexp, 'gi')

        console.log(@get 'regexp')


    processContent: (content)->
        content = content.replace(@get('regexp'), '<span class="bStopWord">$1</span>')
        content = content.replace(/[\f\n\r]/gi, '<br/>')
        @output.update content


SSN.Form = Backbone.View.extend
    initialize: -> 
        @setElement $('#mainForm')[0]
        @$input = $ '#mainInput', @el

    events: 
        'keyup #mainInput': 'changeContent'

    changeContent: ->
        @trigger 'change:content', @$input.val()


SSN.Output = Backbone.View.extend
    initialize: -> 
        @setElement $('.bContent__eOutputText')[0]

    events: 
        'keyup #mainInput': 'processContent'

    update: (content)->
        @$el.html(content)

$ ->
    app = new SSN.App()