class App.M.Password extends Backbone.Model
  urlRoot: '/keys'

  toJSON: ->
    _.pick @attributes, "id", "hidden_url", "hidden_password"

  generate: ->
    @set password: to_utf8 sjcl.random.randomWords(3)

  hide: ->
    cipher = new sjcl.cipher.aes(App.User.get('mainkey'))
    iv     = sjcl.random.randomWords(4)
    @set hidden_url: to_b64 sjcl.bitArray.concat(iv, sjcl.mode.ccm.encrypt(cipher, from_utf8(@get('url')), iv))
    iv     = sjcl.random.randomWords(4)
    @set hidden_password: to_b64 sjcl.bitArray.concat(iv, sjcl.mode.ccm.encrypt(cipher, from_utf8(@get('password')), iv))

  bare: ->
    cipher      = new sjcl.cipher.aes(App.User.get('mainkey'))
    iv              = sjcl.bitArray.bitSlice(sjcl.codec.base64.toBits(@get('hidden_password')), 0, 128)
    hidden_password = sjcl.bitArray.bitSlice(sjcl.codec.base64.toBits(@get('hidden_password')), 128)
    @set password: to_utf8 sjcl.mode.ccm.decrypt(cipher, hidden_password, iv)
    iv          = sjcl.bitArray.bitSlice(sjcl.codec.base64.toBits(@get('hidden_url')), 0, 128)
    hidden_url  = sjcl.bitArray.bitSlice(sjcl.codec.base64.toBits(@get('hidden_url')), 128)
    @set url: to_utf8 sjcl.mode.ccm.decrypt(cipher, hidden_url, iv)

class _Passwords extends Backbone.Collection
  model: App.M.Password

App.M.Passwords = new _Passwords()
