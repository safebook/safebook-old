#= require jquery

#= require spine/spine
#= require spine/ajax

#= require S

#= require model/key

class window.User extends Spine.Model
  @configure "User", "id", "pseudo", "token", "user_key", "pubkey", "seckey", "data"
  @extend Spine.Model.Ajax

  public: ->
    pseudo: @pseudo, token: @token

  toJSON: ->
    pseudo: @pseudo, token: @token, pubkey: @pubkey, data: @data

  auth: (@pseudo, password) ->
    auth = S.auth(@pseudo, password)
    @user_key = auth.user_key
    @token = auth.token
    @

  signup: (pseudo, password) ->
    @auth(pseudo, password)
    up = S.signup(@user_key)
    [@seckey, @pubkey, @data] = [up.seckey, up.pubkey, up.data]
    @save()
    @

  signin: ->

    on_success = (res) =>
      @[key] = val for key, val of res # I need only some (data, pubkey...)
      @seckey = S.bare_seckey @user_key, @data

      for contact in res.contacts
        contact = new Contact(contact)
#       console.log contact.pseudo  buggy
#       console.log contact.shared  something TODO
#       console.log contact.pubkey
        contact.get_shared(@seckey)
#       console.log contact.shared
        Contact.addRecord(contact)
      for key in res.keys
        key = new Key(key)
        console.log key
        Contact.each (contact) =>
          if @id is key.dest_id and contact.id is key.user_id
            key.shared_with(contact)
          if @id is key.user_id and contact.id is key.dest_id
            key.shared_with(contact)
        Key.addRecord(key)
      console.log "msgs"
      for msg in res.msgs
        msg = new Msg(msg)
        console.log msg
        Key.each (key) =>
          if msg.key_tag == key.tag
            console.log key
            msg.bare_with(key)
        console.log msg
        Msg.addRecord(msg)

      @trigger 'ready', @user

    $.ajax {
      type: 'POST'
      url: '/signin'
      contentType: 'application/json'
      data: JSON.stringify @public()
      dataType: 'json'
      success: on_success
    }
