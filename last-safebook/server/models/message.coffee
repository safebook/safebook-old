module.exports = (sequelize, DataTypes) ->
  sequelize.define 'Message',
    key_id:
      type: DataTypes.STRING
    user_id:
      type: DataTypes.INTEGER
    data:
      type: DataTypes.TEXT
