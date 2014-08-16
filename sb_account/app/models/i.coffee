Spine = require('spine')

Circle  = require('models/circle')
Key     = require('models/key')

class I extends Spine.Model
  @configure 'I', 'id'
  @hasMany 'keys', 'models/key' #commonJS
  @hasMany 'friends', 'models/key'
  @hasMany  'circles', 'models/circle' #commonJS

  constructor: ->
    @id = 1

  haveFriend: ->
    @trigger 'friend', user

module.exports = new I()
