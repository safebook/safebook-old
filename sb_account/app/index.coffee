require('lib/setup')

Spine = require('spine')
User  = require('models/user')

class App extends Spine.Controller
  constructor: ->
    super
    Main = require('controllers/main')
    new Main(el: $("body"))

module.exports = App
