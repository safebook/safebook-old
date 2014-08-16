Spine = require('spine')

User    = require('models/user')
Key     = require('models/key')

class Circle extends Spine.Model
  @configure 'Circle', 'data', 'id', 'name', 'members'

  constructor: ->
    super
    @items = []

  insert: (user_id) ->
    user = User.find(user_id)
    value = S.key()
    Key.create {
      value: value
      data: S.hide_key(user.shared(), value)
      user_id: I.id
      dest_id: user_id
      circle_id: @id
    }

  value: ->
    unless @value?
      @value = S.bare(@data, I.mainkey)
    @value

module.exports = Circle
