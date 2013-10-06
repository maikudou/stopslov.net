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
        regexp = '([^а-яА-Я\\-]|\\s|\\r|\\n|\\b)('+_.map(@get('stopWords'), (word)->
            return word.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/gi, "\\$&");
        ).join('|')+')([^а-яА-Я\\-]|\\s)'

        @set 'regexp', new RegExp(regexp, 'gi')

        console.log(@get('regexp'))


    processContent: (content)->
        content = ' ' + content + ' ' #TODO DIRTY HACK
        content = content.replace(/[\f\n\r]/gi, '$& ') #TODO DIRTY HACK
        content = content.replace(@get('regexp'), '$1<span class="bStopWord">$2</span>$3')
        content = content.replace(/([\f\n\r]) /gi, '$&') #TODO DIRTY HACK
        content = content.replace(/[\f\n\r]/gi, '<br/>')
        @output.update content


SSN.Form = Backbone.View.extend
    initialize: -> 
        @setElement $('.bContent')[0]
        @$input = $ '#mainInput', @el
        @$menuItems = @$el.find('.bContent__eMenuItem')
        @$tabs = @$el.find('.bContent__eTab')
        @$listOpener = @$el.find('#listOpener')
        @$wordList = @$el.find('.bContent__eWordsList')

    events: 
        'keyup #mainInput': 'changeContent'
        'click .bContent__eMenuItem': 'switchTab'
        'click #listOpener': 'toggleWords'

    changeContent: ->
        @trigger 'change:content', @$input.val()

    switchTab: (e)->
        $target = $(e.currentTarget)
        
        index = @$menuItems.index($target)
        
        return false if $target.hasClass('bContent__eMenuItem__mState_active')

        @$menuItems.removeClass('bContent__eMenuItem__mState_active')
        $target.addClass('bContent__eMenuItem__mState_active')

        @$tabs.removeClass('bContent__eTab__mState_active')
        @$tabs.eq(index).addClass('bContent__eTab__mState_active')

        console.log(index)
        
        return false

    toggleWords: (e)->
        $target = $(e.currentTarget)

        @$wordList.text(SSNWords.join(', ')).toggleClass('bContent__eWordsList__mState_open')

        if @$wordList.hasClass('bContent__eWordsList__mState_open')
            @$listOpener.text('Закрыть список стоп-слов')
        else
            @$listOpener.text('Открыть список стоп-слов')

        return false


SSN.Output = Backbone.View.extend
    initialize: -> 
        @setElement $('.bContent__eOutputText')[0]

    events: 
        'keyup #mainInput': 'processContent'

    update: (content)->
        @$el.html(content)

$ ->
    app = new SSN.App()