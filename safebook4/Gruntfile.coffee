module.exports = (grunt) ->

  grunt.initConfig
    concat:
      deps:
        files:
          'server/public/dependencies.js': [
            'app/vendor/jquery.min.js'
            'app/vendor/underscore-min.js'
            'app/vendor/backbone-min.js'
            'app/vendor/sjcl.js'
            'app/vendor/socket.io.js'
          ]
    coffee:
      options:
        bare: true
      glob:
        { expand: true, cwd:'server/models', src: ['*.coffee'], dest: 'server/models', ext: '.js' }
      client:
        files:
          'server/public/safebook.js': [
            'app/helpers/*.coffee'
            'app/models/*.coffee'
            'app/controllers/*.coffee'
            'app/boot.coffee'
          ]
      server:
        files:
          'server/public/test.js': [
            'app/helpers/*.coffee'
            'app/models/*.coffee'
            'app/controllers/*.coffee'
            'test/*.coffee'
          ]
    jade:
      dist:
        files:
          "server/public/index.html": "app/views/index.jade"

    stylus:
      dist:
        files:
          "server/public/index.css": "app/stylesheets/*.styl"
    shell:
      test:
        options:
          failOnError: false
        command: 'ruby test.rb'

    watch:
      all:
        files: ['app/**/*']
        tasks: ['default']
        options:
          spawn: false

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-contrib-watch'

  grunt.registerTask 'default', ['concat:deps', 'coffee:client', 'jade', 'stylus']
  grunt.registerTask 'test', ['shell:test']
