Sequelize = require 'sequelize'
_         = require 'underscore'
fs        = require 'fs'

sequelize = new Sequelize(null, null, null,
  dialect: 'sqlite', storage: 'db/development.sqlite')

App = C: {}, M: {}, sockets: {}
App.H = require("#{__dirname}/helpers")(App)
App.M[model] = sequelize.import("#{__dirname}/models/#{model}") for model in _.map(fs.readdirSync("#{__dirname}/models"), (f)-> f.split('.')[0])
App.C[ctrl] = require("#{__dirname}/controllers/#{ctrl}")(App) for ctrl in _.map(fs.readdirSync("#{__dirname}/controllers"), (f)-> f.split('.')[0])

sequelize.sync(force: true).error ->
  console.log "Database sync error"
  exit

express     = require 'express'
cookieParser = require 'cookie-parser'
app = express()
App.store = new express.session.MemoryStore()

app.configure ->
  app.use express.json()
  app.use cookieParser("FIXME")
  app.use express.session(secret: "FIXME", key: 'connect.sid', store: App.store)
  app.use express.static(__dirname + '/public')
  app.use (req, res, next) ->
    console.log('LOG: %s %s >', req.method, req.url)
    console.log JSON.stringify req.body
    next()

app.get    '/users/:pseudo',
  App.C.users.find
app.post   '/users',
  App.C.users.create
app.put    '/users/:pseudo',
  App.C.users.load,
  App.C.users.login
app.get    '/users',
  App.C.users.is_admin,
  App.C.users.findAll

app.post   '/keys',
  App.C.users.load,
  App.C.users.find_dest,
  App.C.keys.create
app.get    '/keys',
  App.C.users.is_admin,
  App.C.keys.findAll

app.post   '/messages',
  App.C.users.load
  App.C.keys.load,
  App.C.messages.create
app.get    '/messages',
  App.C.users.is_admin,
  App.C.messages.findAll

server = app.listen(5555)

App.io = require('socket.io')(server)

App.io.use (socket, next) ->
  req = socket.request
  unless req.headers.cookie
    return next(new Error('Missing Cookies'))
  else
    cookieParser() req, {}, (err) ->
      req.session_id = require('connect').utils.parseSignedCookie(req.cookies['connect.sid'], "FIXME")
      App.store.get req.session_id, (err, session) ->
        if (err) then return next(err)
        if (!session) then return next(new Error('Invalid Session'))
        if (!session.user_id) then return next(new Error('No user id'))
        App.sockets[session.user_id] = socket.id
        req.user_id = session.user_id
        next()

App.io.on 'connection', (socket) ->
  user_id = socket.request.user_id
  socket.on 'disconnect', ->
    delete App.sockets[user_id] if App.sockets[user_id]

console.log("Server listening on port 5555")
