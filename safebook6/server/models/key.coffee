Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (sequelize) ->
  sequelize.define('Key', {
    id:
      type: Sequelize.INTEGER
    user_id:
      type: Sequelize.INTEGER
    dest_id:
      type: Sequelize.INTEGER
    hidden_data:
      type: Sequelize.TEXT
    # server_id:
    # type: Sequelize.INTEGER # auto incr
    # target_id: (polymorph)
  }, {
    timestamps: false
    instanceMethods:
      full: -> _.pick(@,'id', 'user_id', 'dest_id', 'hidden_data')
  })
