Spine = require('spine')

I     = require('models/i')
S     = require('lib/s')
Key   = require('models/key')

class User extends Spine.Model
  @configure 'User', 'id', 'pseudo', 'pubkey'

  #@hasMany 'Key', 'key'

module.exports = User
