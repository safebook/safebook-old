module.exports = (sequelize, DataTypes) ->
  sequelize.define 'Group', {
    id:
      type: DataTypes.STRING
    user_id:
      type: DataTypes.INTEGER
    name:
      type: DataTypes.STRING
    hidden_data:
      type: DataTypes.TEXT
  }, {
    timestamps: false

    instanceMethods:
      full: ->
        id: @id, user_id: @user_id, name: @name, hidden_data: @hidden_data
  }
