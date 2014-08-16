#Account = new User

Spine = require('spine')
User  = require('models/user')

#Account = new User()

class Main extends Spine.Controller

  el: $('body')

  constructor: ->
    @html require("views/index")
    super

  events:
    'focus input'                 : 'reset_input'

    'blur input[name="pseudo"]'   : 'check_pseudo'
    'blur input[name="email"]'    : 'check_email'
    'blur input[name="password"]' : 'check_password'
    'blur input[name="confirm"]'  : 'check_confirm'

    'submit form'                 : 'signup'

  elements:
    'form'                    : 'form'
    'input[name="pseudo"]'    : 'pseudo'
    'input[name="email"]'     : 'email'
    'input[name="password"]'  : 'password'
    'input[name="confirm"]'   : 'confirm'

  reset_input: (e) ->
    $(e.target).removeClass "invalid"

  check_pseudo: ->
    unless /^[a-z0-9_\-]{2,}$/i.test(@pseudo.val())
      @invalid(@pseudo)
    else unless @last_pseudo is @pseudo.val()
      @last_pseudo = @pseudo.val()
      User.exist @pseudo.val(), (ok) =>
        @last_pseudo = @pseudo.val()
        @last_pseudo_ok = ok
        @invalid(@pseudo) unless ok
    else unless @last_pseudo_ok
      @invalid(@pseudo)

  check_email: ->
    unless /^[0-9a-z._-]+@[0-9a-z.-]+\.[a-z]{2,6}$/i.test @email.val()
      @invalid(@email)
    # server check ?

  check_password: ->
    pw = @password.val()
    unless /[0-9]+/.test(pw) && /[a-z]+/.test(pw) and /[A-Z]+/.test(pw) and pw.length >= 8
      @invalid(@password)

  check_confirm: ->
    @invalid(@confirm) if @password.val() isnt @confirm.val()

  invalid: (input) ->
    input.addClass 'invalid'

  signup: (e) ->
    e.preventDefault()
    User.bind 'ajaxSuccess', ->
      alert 'saved'
    User.bind 'ajaxError', (model, xhr) ->
      alert 'error: ' + xhr.responseText
    user = User.fromForm(@form)
    user.birth()
    user.save()

module.exports = Main
