Spine = require('spine')

S     = require('lib/s')

class Key extends Spine.Model
  @configure('Key', 'id'
    'data', 'value',
    'circle_id', 'user_id', 'dest_id')

  creator: -> User.find(@user_id)

  bare: ->
    @value = S.bare(@data, @creator().pubkey)

  value: ->
    @bare() unless @value?
    @value

module.exports = Key
