#= require jquery

#= require spine/spine

#= require model/user
#= require model/contact

#= require controller/contacts

#= require view/signin

class window.Signin extends Spine.Controller

  constructor: ->
    super

    @html JST['view/signin']()
    #@delegateEvents(@events)

    @user = new User()
    @user.on 'ready', (user) =>
      console.log "server is ok :"
      console.log user
      User.addRecord(user)
      new Contacts(el: @el)

  events:
    'click #login' : 'signin',

  signin: =>
    @log 'signin...'
    pseudo = $('#pseudo').val()
    password = $('#password').val()
    @user.auth(pseudo, password).signin()
