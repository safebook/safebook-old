# TODO
# Set a mainkey for password manager and instead of using related pubkey and seckey when sending a key to myself
# Improve authentification for no possible replay (SRP?)

class App.M.User extends Backbone.Model
  urlRoot: '/users'

  idAttribute: 'pseudo'

  toJSON: ->
    @pick "id", "pseudo", "pubkey", "remote_secret", "hidden_seckey", "hidden_mainkey"

  constructor: ->
    super
    unless @isNew()
      @load()
    else
      @on 'sync', @load
    @

  load: =>
    @bare_ecdh() if not @has('seckey') and @has('hidden_seckey')
    @bare_mainkey() if not @has('mainkey') and @has('hidden_mainkey')
    @shared() if not @has('shared') and @has('pubkey')

  log: =>
    shared = if @has('shared') then to_b64(@get('shared')) else "(null)"
    console.log """USER (#{@get('pseudo')}) -->
      pubkey(#{@get('pubkey')})
      shared(#{shared})
    """

  auth: ->
    x00 = sjcl.codec.hex.toBits "0x00000000000000000000000000000000"
    x01 = sjcl.codec.hex.toBits "0x00000000000000000000000000000001"
    x02 = sjcl.codec.hex.toBits "0x00000000000000000000000000000002"
    x03 = sjcl.codec.hex.toBits "0x00000000000000000000000000000003"

    key    = sjcl.misc.pbkdf2(@get('password'), @get('pseudo'))
    cipher = new sjcl.cipher.aes(key)

    @set 'local_secret', sjcl.bitArray.concat(cipher.encrypt(x00), cipher.encrypt(x01))
    @set 'remote_secret',  to_b64 sjcl.bitArray.concat(cipher.encrypt(x02), cipher.encrypt(x03))

  create_ecdh: ->
    @set seckey: sjcl.bn.random(curve.r, 6)
    @set pubkey: to_b64 curve.G.mult(@get('seckey')).toBits()

  hide_ecdh: ->
    @set hidden_seckey: App.S.hide_seckey(@get('local_secret'), @get('seckey'))

  bare_ecdh: ->
    @set seckey: App.S.bare_seckey(@get('local_secret'), @get('hidden_seckey'))

  create_mainkey: ->
    @set mainkey: sjcl.random.randomWords(8)

  hide_mainkey: ->
    @set hidden_mainkey: App.S.hide(@get('local_secret'), @get('mainkey'))

  bare_mainkey: ->
    @set mainkey: App.S.bare(@get('local_secret'), @get('hidden_mainkey'))

  shared: (user) ->
    point = curve.fromBits(from_b64(@get('pubkey'))).mult(App.User.get('seckey'))
    @set shared: sjcl.hash.sha256.hash point.toBits()

  keys: ->
    keys = App.M.Keys.filter((o)=> o.user_id == @get('id') || App.M.Keys.where(dest_id: @get('id')))

class _Users extends Backbone.Collection
  model: App.M.User

App.M.Users = new _Users()
