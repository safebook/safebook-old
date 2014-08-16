require('lib/setup')

Spine = require('spine')
Main  = require("controllers/main")

class App extends Spine.Controller
  constructor: ->
    super
    @main = new Main()
    #@html @main.$el
    #@html @main.render().el

module.exports = App
