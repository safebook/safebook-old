module.exports = (grunt) ->

  grunt.initConfig
    coffee:
      dist:
        files:
          'client/js/main.js': 'client/coffee/main.coffee'

    browserify:
      dist:
        files:
          'server/public/safebook.js': ['client/js/main.js']

    uglify:
      dist:
        files:
          'server/public/safebook.js': ['client/safebook.js']
    jade:
      compile:
        files: 'server/public/index.html': 'client/index.jade'

  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jade'

  grunt.registerTask 'default', ['coffee', 'browserify', 'jade']
