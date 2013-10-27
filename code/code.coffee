window.SSN = {}
window.app = {}

SSN.App = Backbone.Model.extend
    defaults: 
        stopWords: window.SSNWords
        regexp: //

    initialize: ->
        @form = new SSN.Form {model: @}
        @output = new SSN.Output()

        @form.model = @

        if localStorage.getItem('userStopWords')?
            @set 'stopWords', JSON.parse localStorage.getItem('userStopWords')

        @buildRegexp()

        @listenTo @form, 'change:content', @processContent
        @listenTo @form, 'change:stopWords', @changeWords
        @on 'change:stopWords', @save

    buildRegexp: ->
        regexp = '([^а-яА-Я\\-]|\\s|\\r|\\n|\\b)('+_.map(@get('stopWords'), (word)->
            return word.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/gi, "\\$&");
        ).join('|')+')([^а-яА-Я\\-]|\\s)'

        @set 'regexp', new RegExp(regexp, 'gi')

        console.log(@get('regexp'))

    changeWords: (changeStack)->
        console.log changeStack
        if changeStack.removed?
            @excludeWords changeStack.removed

        if changeStack.added?
            @includeWords changeStack.added

    includeWords: (words)->
        if _.isString(words) or _.isArray(words)
            @set 'stopWords', _.union @get('stopWords'), words
            @buildRegexp()

    excludeWords: (words)->
        if _.isString(words) or _.isArray(words)
            @set 'stopWords', _.difference @get('stopWords'), words
            @buildRegexp()

    processContent: (content)->
        content = ' ' + content + ' ' #TODO DIRTY HACK
        content = content.replace(/[\f\n\r]/gi, '$& ') #TODO DIRTY HACK
        content = content.replace(@get('regexp'), '$1<span class="bStopWord">$2</span>$3')
        content = content.replace(/([\f\n\r]) /gi, '$&') #TODO DIRTY HACK
        content = content.replace(/[\f\n\r]/gi, '<br/>')
        @output.update content

    save: ->
        localStorage.setItem 'userStopWords', JSON.stringify @get('stopWords')


SSN.Form = Backbone.View.extend
    initialize: -> 
        @setElement $('.bContent')[0]
        @$input = $ '#mainInput', @el
        @$menuItems = @$el.find('.bContent__eMenuItem')
        @$tabs = @$el.find('.bContent__eTab')
        @$listOpener = @$el.find('#listOpener')
        @$wordList = @$el.find('.bContent__eWordsList')

        @listenTo @model, 'change:stopWords', @renderWords
        @listenTo @model, 'change:regexp', @changeContent

    events: 
        'keyup #mainInput': 'changeContent'
        'click .bContent__eMenuItem': 'switchTab'
        'click #listOpener': 'toggleWords'
        'click .jsWord': 'removeWord'

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

        @renderWords()
        @$wordList.toggleClass('bContent__eWordsList__mState_open')

        if @$wordList.hasClass('bContent__eWordsList__mState_open')
            @$listOpener.text('Закрыть список стоп-слов')
        else
            @$listOpener.text('Открыть список стоп-слов')

        return false

    renderWords: ->
        words = _.map @model.get('stopWords'), (word)->
            return "<span class=\"bContent__eWordsListItem jsWord\">#{word}</span>"

        @$wordList.html words.join('') + '<input type="text" placeholder="+" class="bContent__eWordsListInput jsWordAdd">'

        $('.jsWordAdd').unbind('change').bind 'change', _.bind(@addWord, @)

    addWord: (e)->
        newWord = $(e.currentTarget).val().replace(/^\s\s*/, '').replace(/\s\s*$/, '')
        newWord = newWord.slice(0,1).toUpperCase() + newWord.slice(1).toLowerCase()

        @trigger 'change:stopWords', {added: [newWord]} if newWord.length > 0
        $(e.currentTarget).val('')

    removeWord: (e)->
        $(e.currentTarget).css('transform', 'scaleX(0)')
        setTimeout =>               #TODO normalize animation
            @trigger 'change:stopWords', {removed: [$(e.currentTarget).text()]}
        , 500


SSN.Output = Backbone.View.extend
    initialize: -> 
        @setElement $('.bContent__eOutputText')[0]

    events: 
        'keyup #mainInput': 'processContent'

    update: (content)->
        @$el.html(content)

$ ->
    window.app = new SSN.App()
