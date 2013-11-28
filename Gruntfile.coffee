module.exports = (grunt)->
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-jade'
    grunt.loadNpmTasks 'grunt-contrib-less'
    grunt.loadNpmTasks 'grunt-contrib-concat'

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
            backend:
                files: [
                    expand: true
                    cwd: 'backend'
                    src: ['**/*.coffee']
                    dest: 'backend'
                    ext: '.js'
                ]

        jade:
            compile:
                files:
                    "build/index.html": "code/template.jade"
                options:
                    pretty: true

        less:
            compile:
                files:
                    "build/global.css": "code/global.less"

        concat:
            production:
                separator: '\n'
                src: ['code/js/libs/jquery.js', 'code/js/libs/underscore.js', 'code/js/libs/backbone.js', 'code/js/words.js', 'code/js/code.js']
                dest: 'build/global.js'

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
            