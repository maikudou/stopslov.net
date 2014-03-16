((root, factory) ->
    if typeof define is 'function' and define.amd
        define ['underscore', 'exports', 'jquery'], (_, exports, $)->
            root.SSN = factory root, exports, _, $

    else if typeof exports isnt 'undefined'
        _ = require 'underscore'
        factory root, exports, _

    else
        root.SSN = factory root, {}, root._, $

) this, (root, SSN, _, $)->

    previousSSN = root.SSN

    SSN.noConflict = ->
        root.SSN = previousSSN
        return @

    class SSN.Marker
        preferences:
            useDictionaries: true
            dictionaries:
                dic: '../dictionaries/ru_RU.dic.json'
                aff: '../dictionaries/ru_RU.aff.json'
            localRegexp: true
            template:
                beforeWord: '<span class="bStopWord">'
                afterWord: '</span>'

        constructor: (preferences, readyCallback)->
            _.extend @preferences, preferences
            @_loadDictionaries(readyCallback)
            return @


        _loadDictionaries: (callback)->
            if typeof require isnt 'undefined'
                SSN.dictionary = require @preferences.dictionaries.dic
                SSN.affixes = require @preferences.dictionaries.aff
                callback() if typeof callback is 'function'

            else if typeof $ isnt 'undefined' and $.getJSON?
                json =
                    dic: false
                    aff: false

                progress = (done)->
                    json[done] = true

                    notLoaded = _.filter json, (status)->
                        return !status

                    callback() if typeof callback is 'function' and loaded.length is 0

                $.getJSON @preferences.dictionaries.dic, (data)->
                    SSN.dictionary = data
                    progress 'dic'

                $.getJSON @preferences.dictionaries.aff, (data)->
                    SSN.affixes = data
                    progress 'aff'

            else
                #TODO нужно сделать отключение словарей
                @preferences.dictionaries = false
        

        buildRegexp: (words)->
            wordForms = []
            regexp = '([^а-яА-Я\\-]|\\s|\\r|\\n|\\b)('+_.map(words, (word)->
                if variantIndex = SSN.dictionary[word.toLowerCase()]
                    for variantIndexSingle in variantIndex.split('')
                    
                        for ending, variants of SSN.affixes[variantIndexSingle]
                            if ending == '0'
                                for variant in variants
                                    regexp = new RegExp(variant[1]+'$', 'gi')
                                    wordForms.push word+variant[0] if regexp.test(word)
                            else
                                for variant in variants
                                    regexp = new RegExp(variant[1]+'$', 'gi')
                                    if variant[0] != '0' and regexp.test(word)
                                        replaceRegexp = new RegExp(ending+'$', 'gi')
                                        wordForms.push word.replace(replaceRegexp, variant[0])

                return word.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/gi, "\\$&");
            ).join('|')+wordForms.join('|')+')([^а-яА-Я\\-]|\\s)'

            newregexp = new RegExp(regexp, 'gi')
            @regexp = newregexp if @preferences.localRegexp
            return newregexp

        processContent: (content, regexp)->
            if typeof regexp is 'undefined'
                regexp = @regexp

            content = ' ' + content + ' ' #TODO DIRTY HACK
            content = content.replace(/[\f\n\r]/gi, '$& ') #TODO DIRTY HACK
            content = content.replace(regexp, "$1#{@preferences.template.beforeWord}$2#{@preferences.template.afterWord}$3")
            content = content.replace(/([\f\n\r]) /gi, '$&') #TODO DIRTY HACK
            content = content.replace(/[\f\n\r]/gi, '<br/>')
            return content

    return SSN