window.SSN = {} unless SSN?
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

    getTransitionEventsString: ->
        if typeof window.ontransitionend is 'object' and typeof window.onwebkittransitionend is 'object'
            return 'transitionend oTransitionEnd otransitionend MSTransitionEnd'

        else
            return 'transitionend webkitTransitionEnd oTransitionEnd otransitionend MSTransitionEnd'


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
        'click #listOpener': 'toggleWords'
        'click .jsWord': 'removeWord'

    changeContent: ->
        @trigger 'change:content', @$input.val()

    selectTab: (tabName)->
        index = @$tabs.closest('#'+tabName).index('.bContent__eTab')
        @$tabs.removeClass('bContent__eTab__mState_active')
        @$tabs.closest('#'+tabName).addClass('bContent__eTab__mState_active')

        @$menuItems.removeClass('bContent__eMenuItem__mState_active')
        @$menuItems.eq(index).addClass('bContent__eMenuItem__mState_active')

    toggleWords: (e)->
        $target = $(e.currentTarget)

        @renderWords()
        @$wordList.toggleClass('bContent__eWordsList__mState_open')

        if @$wordList.hasClass('bContent__eWordsList__mState_open')
            @$listOpener.text('Закрыть список стоп-слов')

            SSN.Analytics.trackEvent
                category: 'UI'
                action: 'open'
                label: 'StopList'

        else
            @$listOpener.text('Открыть список стоп-слов')

            SSN.Analytics.trackEvent
                category: 'UI'
                action: 'close'
                label: 'StopList'

        return false

    renderWords: ->
        words = _.map @model.get('stopWords'), (word)->
            return "<span class=\"bContent__eWordsListItem jsWord\">#{word}</span>"

        @$wordList.html words.join(', ') + '<input type="text" placeholder="+" class="bContent__eWordsListInput jsWordAdd">'

        $('.jsWordAdd').unbind('change').bind 'change', _.bind(@addWord, @)

    addWord: (e)->
        newWord = $(e.currentTarget).val().replace(/^\s\s*/, '').replace(/\s\s*$/, '')
        newWord = newWord.slice(0,1).toUpperCase() + newWord.slice(1).toLowerCase()

        @trigger 'change:stopWords', {added: [newWord]} if newWord.length > 0
        $(e.currentTarget).val('')

        SSN.Analytics.trackEvent
            category: 'Words'
            action: 'add'
            value: newWord

    removeWord: (e)->
        $target = $(e.currentTarget)
        $target.addClass('mHide')

        $target.one @model.getTransitionEventsString(), =>
            @trigger 'change:stopWords', 
                removed: [$target.text()]

        SSN.Analytics.trackEvent
            category: 'Words'
            action: 'remove'
            value: $target.text()


SSN.Output = Backbone.View.extend
    initialize: -> 
        @setElement $('.bContent__eOutputText')[0]

    events: 
        'keyup #mainInput': 'processContent'

    update: (content)->
        @$el.html(content)

SSN.Router = Backbone.Router.extend
    routes:
        '': 'ssnForm'
        '/': 'ssnForm'
        'about/words/': 'aboutWords'
        'about/service/': 'aboutService'

    ssnForm: ->
        app.form.selectTab('ssnForm')

    aboutWords: ->
        app.form.selectTab('aboutWords')

    aboutService: ->
        app.form.selectTab('aboutService')

$ ->
    window.app = new SSN.App()
    window.router = new SSN.Router()
    Backbone.history.start()
