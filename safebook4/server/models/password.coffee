module.exports = (sequelize, DataTypes) ->
  sequelize.define 'Password', {
    id:
      type: DataTypes.STRING
    user_id:
      type: DataTypes.INTEGER
    hidden_url:
      type: DataTypes.TEXT
    hidden_password:
      type: DataTypes.TEXT
  }, {
    timestamps: false

    instanceMethods:
      full: ->
        id: @id, user_id: @user_id, hidden_url: @hidden_url, hidden_password: @hidden_password
  }
