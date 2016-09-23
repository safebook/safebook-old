module.exports = (sequelize, DataTypes) ->
  User = sequelize.define 'User', {
    id:
      type: DataTypes.STRING
    pseudo:
      type: DataTypes.STRING
      unique: true
      validate:
        len: [2, 16]
        # validate: isA permissif (casi tous les caracteres (WHY NOT TOUS?))
    password_hash:
      type: DataTypes.STRING
    password_salt:
      type: DataTypes.STRING
    pubkey:
      type: DataTypes.TEXT
      unique: true
      # validate: isA:
    data:
      type: DataTypes.TEXT
      # validate: isA:
  }, {
    timestamps: false

    instanceMethods:
      public: ->
        id: @id, pseudo: @pseudo, pubkey: @pubkey
      full: ->
        id: @id, pseudo: @pseudo, pubkey: @pubkey, data: @data
  }


### TODO:
Mettre les 3 "unique: true" dans la meme requete sql (et check les contraintes sur la base) ou 0 requete et seulement des contraintes sur la base
###
