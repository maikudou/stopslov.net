module.exports = (grunt)->
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-less'
    grunt.loadNpmTasks 'grunt-contrib-concat'
    grunt.loadNpmTasks 'grunt-contrib-copy'
    grunt.loadNpmTasks 'node-srv'

    readline = require 'readline'
    path     = require 'path'
    fs       = require 'fs'


    grunt.initConfig 
        coffee:
            compile:
                files: [
                    expand: true
                    cwd: 'dist/coffee/'
                    src: ['**/*.coffee']
                    dest: 'dist/js'
                    ext: '.js'
                ]

        jade:
            pages:
                cwd: 'dist/pages/'
                src: '*.jade'
                dest: 'build/'
                ext: '.html'
                options:
                    pretty: true

        less:
            compile:
                files:
                    "build/global.css": "dist/less/global.less"

        concat:
            production:
                separator: '\n'
                src: ['dist/js/libs/jquery.js', 'dist/js/libs/underscore.js', 'dist/js/libs/backbone.js', 'dist/js/*.js']
                dest: 'build/global.js'

        copy:
            dictionaries:
                src: 'dictionaries/*.json'
                dest: 'build/'

            static:
                expand: true
                cwd: 'dist/static/'
                src: '**/*'
                dest: 'build/'
                filter: 'isFile'

        affToJson:
            cwd: 'dictionaries/'
            src: 'ru_RU.aff'
            dest: 'dictionaries/'
            ext: '.json'

        dicToJson:
            cwd: 'dictionaries/'
            src: 'ru_RU.dic'
            dest: 'dictionaries/'
            ext: '.json'

        srv:
            server:
                port: 8000
                root: 'build'
                index: 'index.html'
                404: 'build/404.html'
    
        watch:
            coffee:
                files: ['dist/coffee/**/*.coffee']
                tasks: ['coffee:compile']

            jade:
                files: ['dist/pages/*.jade']
                tasks: ['jade']

            less:
                files: ['dist/less/*.less']
                tasks: ['less:compile']

            concat:
                files: ['dist/**/*.js']
                tasks: ['concat:production']


    grunt.registerTask 'default', 'watch'
    grunt.registerTask 'build', ['processDictionaries', 'coffee', 'jade', 'less', 'concat', 'copy']


    grunt.registerMultiTask 'jade', 'Compile jade to HTML', ->
        jade = require 'jade'

        for file in this.filesSrc
            filepath = path.join(@data.cwd, file)

            try
                compiled = jade.compile grunt.file.read(filepath), grunt.util._.extend({filename: filepath}, @data.options or {})
                html = compiled.call @, @data.extraData or {}

                filename = path.basename file, path.extname file
                savePath = path.join @data.dest, filename+(@data.ext or '.html')

                grunt.file.write savePath, html
                grunt.log.ok "Rendered \"#{filepath}\" at #{grunt.template.today()}"

            catch e
                grunt.log.error "Jade render error: #{e}"


    grunt.registerTask 'processDictionaries', ['affToJson', 'dicToJson']


    grunt.registerTask 'affToJson', 'Processing OpenOffice affix file to JSON', ->
        done = @async()
        data = grunt.config.get('affToJson')

        stream = fs.createReadStream path.join data.cwd, data.src
        stream.on 'end', ->
            #console.log(affixObject)
            fs.writeFileSync path.join(data.dest, data.src+data.ext), JSON.stringify(affixObject, null, '    ')
            
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


    grunt.registerTask 'dicToJson', 'Processing OpenOffice dictionary file to JSON', ->
        done = @async()
        data = grunt.config.get('dicToJson')

        stream = fs.createReadStream path.join data.cwd, data.src
        stream.on 'end', ->
            #console.log(affixObject)
            fs.writeFileSync path.join(data.dest, data.src+data.ext), JSON.stringify(dicObject, null, '    ')
            
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

