_ = require 'underscore'

module.exports = (App) ->

  # Middlewares

  load: (req, res, next) ->
    res.json(401, null) unless req.body.key_id
    App.M.key.find(where: id: req.body.key_id).done (err, key) ->
      return res.json(401, null) if err or not key
      req.key = key
      next()

  # Controllers

  create: (req, res) ->
    key = req.body
    key.id = App.H.gen_id()
    key.user_id = req.user.id
    App.M.key.create(key).done (err, key) ->
      return res.json(401, null) if err
      dest = App.sockets[key.dest_id]
      if dest
        data = users: [req.user.public()], keys: [key], messages: []
        App.io.sockets.connected[dest].emit('update', data)
      res.json(key)

  findAll: (req, res) ->
    App.M.key.findAll().done (err, keys) ->
      if err or !keys
        res.json 401, error: "Error or no keys"
      else
        res.json 200, keys
