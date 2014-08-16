Spine = require('spine')

S     = require('lib/S')

class User extends Spine.Model
  @configure 'User', 'pseudo', 'email',
    'pubkey', 'seckey', 'token', 'data', 'datakey'

  @extend Spine.Model.Ajax

  @exist: (pseudo, callback) ->
    url = [@url(), pseudo].join('/')
    $.ajax(url).done(=> callback(false)).fail(=> callback(true))

  birth: ->
    keys = S.login(@pseudo, @password)
    ec = S.ec_create()

    @datakey  = keys.datakey
    @token    = keys.token
    @pubkey   = ec.pubkey
    @seckey   = ec.seckey
    @data     = S.armor(S.hide_seckey(@datakey, @seckey))

  toJSON: ->
    result = {}
    fields = ['pseudo', 'email', 'pubkey', 'token', 'data']
    for key of @
      result[key] = @[key] if fields.indexOf(key) isnt -1
    result

module.exports = User
