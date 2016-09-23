#= require jquery

#= require spine/spine

#= require model/user

class window.Signup extends Spine.Controller
  el: $ '#signup'

  constructor: ->
    super
    @user = new User()
    @user.on 'ajaxSuccess', (status, user) =>
      @user.id = user.id

  events:
    'click button': 'signup'

  signup: =>
    pseudo = $('#pseudo').val()
    password = $('#password').val()
    @user.signup(pseudo, password)
