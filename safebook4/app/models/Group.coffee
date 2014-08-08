class App.M.Group extends Backbone.Model
  urlRoot: '/groups'

  toJSON: ->
    _.pick @attributes, "id", "user_id", "name", "hidden_data"

  generate: (user) ->
    cipher = new sjcl.cipher.aes(user.get('shared')) # FIX : user mainkey
    iv     = sjcl.random.randomWords(4)
    data   = sjcl.random.randomWords(8)
    @set
      user_id: user.get 'pseudo'
      data: data
      hidden_data: sjcl.codec.base64.fromBits(sjcl.bitArray.concat(iv, sjcl.mode.ccm.encrypt(cipher, data, iv)))
      # S.armor(S.crypt(contact.get('shared'), data))
    @

class _Groups extends Backbone.Collection
  model: App.M.Group

App.M.Groups = new _Groups()
