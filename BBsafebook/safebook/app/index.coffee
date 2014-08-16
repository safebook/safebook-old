require('lib/setup')

Spine = require('spine')

S = require('lib/safebook')

class App extends Spine.Controller
  constructor: ->
    super
    @html require("views/index")
  events:
    "click button" : "login"

  login: ->
    console.log S.sjcl.misc.pbkdf2 $("#password").val(), $("#pseudo").val()
module.exports = App
