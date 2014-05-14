module.exports = (grunt)->
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-jade'
    grunt.loadNpmTasks 'grunt-contrib-less'
    grunt.loadNpmTasks 'grunt-contrib-concat'
    grunt.loadNpmTasks 'grunt-contrib-copy'
    grunt.loadNpmTasks 'node-srv'

    grunt.initConfig
        coffee:
            compile:
                files: [
                    expand: true
                    cwd: 'code'
                    src: ['**/*.coffee']
                    dest: 'code/js'
                    ext: '.js'
                ]

        jade:
            compile:
                files:
                    "build/index.html": "code/template.jade"
                    "build/frame.html": "code/frame.jade"
                options:
                    pretty: true

        less:
            compile:
                files:
                    "build/global.css": "code/global.less"

        concat:
            production:
                separator: '\n'
                src: ['code/js/libs/jquery.js','code/js/libs/rangy-core.js', 'code/js/libs/rangy-selectionsaverestore.js', 'code/js/libs/underscore.js', 'code/js/libs/backbone.js', 'code/js/words.js', 'code/js/code.js', 'code/js/analytics.js']
                dest: 'build/global.js'

        copy:
            production:
                src: 'dictionaries/*.json'
                dest: 'build/'

        srv:
            server:
                port: 8000
                root: 'build'
                index: 'index.html'

        watch:
            coffee:
                files: ['code/**/*.coffee']
                tasks: ['coffee:compile']

            jade:
                files: ['code/*.jade']
                tasks: ['jade:compile']

            less:
                files: ['code/*.less']
                tasks: ['less:compile']

            concat:
                files: ['code/**/*.js']
                tasks: ['concat:production']


    grunt.registerTask 'default', 'watch'
    grunt.registerTask 'build', ['coffee', 'jade', 'less', 'concat', 'copy']

    grunt.registerTask 'processDictionaries', ['processAff', 'processDic']

    grunt.registerTask 'processAff', 'Processing OpenOffice affix file to JSON', ->
        done = @async()
        fs = require 'fs'
        readline = require 'readline'

        stream = fs.createReadStream('dictionaries/ru_RU.aff')
        stream.on 'end', ->
            #console.log(affixObject)
            fs.writeFileSync "dictionaries/ru_RU.aff.json", JSON.stringify(affixObject, null, '    ')

            done true

        affixObject = {}

        rd = readline.createInterface
            input: stream,
            output: process.stdout,
            terminal: false

        rd.on 'line', (line)->
            unless line == ''
                lineArray = line.split(' ')

                return if lineArray[2] == 'Y'

                lineArray.shift()
                lineIndex = lineArray.shift()

                affixObject[lineIndex] = {} unless affixObject[lineIndex]?

                lineString = lineArray.shift()

                affixObject[lineIndex][lineString] = [] unless affixObject[lineIndex][lineString]?

                affixObject[lineIndex][lineString].push lineArray

    grunt.registerTask 'processDic', 'Processing OpenOffice dictionary file to JSON', ->
        done = @async()
        fs = require 'fs'
        readline = require 'readline'

        stream = fs.createReadStream('dictionaries/ru_RU.dic')
        stream.on 'end', ->
            #console.log(affixObject)
            fs.writeFileSync "dictionaries/ru_RU.dic.json", JSON.stringify(dicObject, null, '    ')

            done true

        dicObject = {}

        rd = readline.createInterface
            input: stream,
            output: process.stdout,
            terminal: false

        rd.on 'line', (line)->
            unless line == ''
                lineArray = line.split('/')

                lineIndex = lineArray.shift()

                dicObject[lineIndex] = {} unless dicObject[lineIndex]?

                if lineArray.length == 0
                    dicObject[lineIndex] = null
                    return false

                dicObject[lineIndex] = lineArray[0]

