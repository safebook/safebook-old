Sequelize = require 'sequelize'
_         = require 'underscore'
async     = require 'async'

module.exports = (App) ->

  create: (req, res) ->
    message = req.body
    message.user_id = req.user.id
    message.id = App.H.gen_id()
    App.M.message.create(message).done (err, message) ->
      res.json(401, null) if err
      dest = App.sockets[req.key.dest_id]
      if dest
        data = users: [], keys: [], messages: [message]
        App.io.sockets.connected[dest].emit('update', data)
      res.json(200, message)

  findAll: (req, res) ->
    App.M.message.findAll().done (err, messages) ->
      if err or !messages
        res.json 401, error: "Error or no messages"
      else
        res.json 200, messages
