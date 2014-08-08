module.exports = (sequelize, DataTypes) ->
  sequelize.define 'Group', {
    id:
      type: DataTypes.STRING
    user_id:
      type: DataTypes.STRING
    dest_id:
      type: DataTypes.STRING
    group_id:
      type: DataTypes.STRING
    hidden_data:
      type: DataTypes.TEXT
  }, {
    timestamps: false

    instanceMethods:
      full: ->
        id: @id, user_id: @user_id, dest_id: @dest_id, group_id: @group_id, hidden_data: @hidden_data
  }
