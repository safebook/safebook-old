class Key extends Spine.Model
  @configure "Key", "tag", "user_id", "dest_id", "value", "data"
  @extend Spine.Model.Ajax

  gen: (friend) ->
    @tag = S.tag()
    key = S.new_key(friend.shared)
    @value = key.value
    @data = key.data
    @

  toJSON: ->
    tag: @tag, user_id: @user_id, dest_id: @dest_id, data: @data

class Contact extends Spine.Model
  @configure "Contact", "id", "pseudo", "pubkey", "shared"
  @extend Spine.Model.Ajax

  url: ->
    if @id? then 'users/' + @id else 'users'

  get_shared: (seckey) =>
    @shared = S.get_shared(seckey, @pubkey)

class User extends Spine.Model
  @configure "User", "id", "pseudo", "token", "user_key", "pubkey", "seckey", "data"
  @extend Spine.Model.Ajax

  sign: ->
    pseudo: @pseudo, token: @token

  toJSON: ->
    pseudo: @pseudo, token: @token, pubkey: @pubkey, data: @data

  auth: (@pseudo, password) ->
    auth = S.auth(@pseudo, password)
    @user_key = auth.user_key
    @token = auth.token

  add_key: (friend) ->
    key = new Key(user_id: @id, dest_id: friend.id)
    key.gen(friend).save()
    console.log key

  signup: (pseudo, password) ->
    @auth(pseudo, password)
    up = S.signup(@user_key)
    [@seckey, @pubkey, @data] = [up.seckey, up.pubkey, up.data]
    @save()

  signin: (pseudo, password) ->
    @auth(pseudo, password)
    $.ajax {
      type: 'POST'
      url: '/signin'
      contentType: 'application/json'
      data: JSON.stringify @sign()
      dataType: 'json'
      success: (res) =>
        @[key] = val for key, val of res
        @seckey = S.bare_seckey @user_key, @data
        @trigger 'ajaxSuccess'
    }

$ ->
  class Signup extends Spine.Controller
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

  class Signin extends Spine.Controller
    el: $ '#signin'

    constructor: ->
      super
      @user = new User()
      @user.on 'ajaxSuccess', =>
        console.log "loaded"
        console.log @user

      Contact.on 'ajaxSuccess', (a, b, xhr) =>
        console.log 'ajax'
        console.log xhr.responseText
        #console.log Contact.all()

      Contact.on 'refresh', (contact, o) =>
        console.log 'refresh'
        contact = contact[0]
        contact.get_shared(@user.seckey)
        console.log contact
        @user.add_key(contact)

    events:
      'click #login' : 'signin',
      'click #add'   : 'add_friend'

    signin: =>
      console.log 'signin'
      pseudo = $('#pseudo').val()
      password = $('#password').val()
      @user.signin(pseudo, password)

    add_friend: =>
      console.log 'add_friend'
      Contact.fetch(id: $('#friend').val())
      # Contact.on 'ajaxSuccess', (a, b, xhr) =>
      #   @contact.get_shared(@user.seckey)
      #   console.log @contact
      #   @user.add_key(@contact.id, @contact.shared)

  new Signup()
  new Signin()
