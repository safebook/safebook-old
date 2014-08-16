Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (sequelize) ->
  sequelize.define('Message', {
    id:
      type: Sequelize.INTEGER
    user_id:
      type: Sequelize.INTEGER
    key_id:
      type: Sequelize.INTEGER
    hidden_data:
      type: Sequelize.TEXT
    # server_id:
    # type: Sequelize.INTEGER # auto incr
  }, {
    timestamps: false
    instanceMethods:
      full: -> _.pick(@, 'id', 'user_id', 'key_id', 'hidden_data')
  })
