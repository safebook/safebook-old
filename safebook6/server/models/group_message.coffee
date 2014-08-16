module.exports = (sequelize, DataTypes) ->
  sequelize.define 'Group_message', {
    group_id:
      type: DataTypes.STRING
    user_id:
      type: DataTypes.INTEGER
    hidden_data:
      type: DataTypes.TEXT
  }, {
    timestamps: false

    instanceMethods:
      full: ->
        id: @id, group_id: @group_id, user_id: @user_id, hidden_data: @hidden_data
  }
