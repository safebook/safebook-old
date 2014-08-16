Sequelize = require 'sequelize'
_         = require 'underscore'
async     = require 'async'

module.exports = (App) ->

  # Middlewares

  is_admin: (req, res, next) -> next() # open for now

  load: (req, res, next) ->
    return res.json(401, null) unless req.session.user_id
    App.M.user.find(where: id: req.session.user_id).done (err, user) ->
      return res.json(401, null) if err
      req.user = user
      next()

  find_dest: (req, res, next) ->
    return res.json(401, null) unless req.body.dest_id
    App.M.user.find(where: id: req.body.dest_id).done (err, user) ->
      return res.json(401, null) if err or not user
      req.dest = user
      next()

  # Controllers

  create: (req, res) ->
    user = req.body
    user.id = App.H.gen_id()
    # work to do
    user.remote_secret_salt = App.H.gen_salt()
    user.remote_secret_hash = App.H.hash(req.body.remote_secret, user.remote_secret_salt)
    App.M.user.create(user).done (err, user) ->
      return res.json(401, null) if err
      req.session.user_id = user.id
      res.json 201, user

  findAll: (req, res) ->
    App.M.user.findAll().done (err, users) ->
      return res.json(401, null) if err or !users
      res.json 200, users

  find: (req, res) ->
    pseudo = req.params.pseudo
    App.M.user.find(where: pseudo: pseudo).done (err, user) ->
      return res.json(401, null) if err or !user
      res.json 200, user.public()

  login: (req, res) ->
    data = user_keys = user_contacts = null
    async.series [
      (next) ->
        App.M.user.find(where: pseudo: req.params.pseudo).done (err, user) ->
          if err or not user or App.H.hash(req.body.token, user.password_salt) isnt user.password_hash # do async
            return next("No such alias / password", null)
          data = user.full()
          next(err, null)
      , (next) ->
        App.M.key.findAll(where: Sequelize.or({user_id: data.id}, {dest_id: data.id})).done (err, keys) ->
          data.keys = (key.full() for key in keys)
          user_keys = (key.id for key in keys)
          user_contacts = _.union (key.user_id for key in keys), (key.dest_id for key in keys)
          next(err, null)
      , (next) ->
        App.M.user.findAll(where: id: user_contacts).done (err, users) ->
          data.users = (user.public() for user in users)
          next(err, null)
      , (next) ->
        App.M.message.findAll(where: key_id: user_keys).done (err, messages) ->
          data.messages = (message.full() for message in messages)
          next(err, null)
    ], (err)->
      res.json(401, null) if err
      req.session.user_id = data.id
      res.json 200, data
