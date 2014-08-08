Sequelize = require 'sequelize'
_         = Sequelize.Utils._

### opti to do :
3 uniques -> 1 requete sql ou 0 et contraintes sur la base
###

module.exports = (sequelize) ->
  return sequelize.define('User', {
    id:
      type: Sequelize.INTEGER
    pseudo:
      type: Sequelize.STRING
      unique: true
    remote_secret_hash:
      type: Sequelize.STRING
    remote_secret_salt:
      type: Sequelize.STRING
    pubkey:
      type: Sequelize.TEXT
      unique: true
      # validate: isA:
    hidden_seckey:
      type: Sequelize.TEXT
      # validate: isA:
    hidden_mainkey:
      type: Sequelize.TEXT
      # validate: isA:
  }, {
    instanceMethods:
      public: -> _.pick(@, 'id', 'pseudo', 'pubkey')
      full: ->
        _.pick(@, 'id', 'pseudo', 'pubkey', 'hidden_seckey', 'hidden_mainkey')
    timestamps: false
  })
