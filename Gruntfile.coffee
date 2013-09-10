module.exports = (grunt)->
    grunt.loadNpmTasks 'grunt-contrib-coffee'
    grunt.loadNpmTasks 'grunt-contrib-watch'
    grunt.loadNpmTasks 'grunt-contrib-jade'
    grunt.loadNpmTasks 'grunt-contrib-less'

    grunt.initConfig 
        coffee:
            compile:
                files: [
                    expand: true
                    cwd: 'coffee'
                    src: ['code/**/*.coffee']
                    dest: 'build/js'
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


    grunt.registerTask 'default', 'watch'
            