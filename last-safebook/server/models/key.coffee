module.exports = (sequelize, DataTypes) ->
  sequelize.define 'Key',
    id:
      type: DataTypes.STRING
    user_id:
      type: DataTypes.INTEGER
    dest_id:
      type: DataTypes.INTEGER
    data:
      type: DataTypes.TEXT
