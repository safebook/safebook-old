express   = require 'express'
Sequelize = require "sequelize"
_         = Sequelize.Utils._

# helpers
gen_salt = -> "badsalt" # fix
hash = (password, salt) -> password # fix

# controllers
ready = ->
  app = express()
  app.use express.logger('tiny')
  app.use express.static(__dirname + '/public')
  app.use express.json()
  app.use express.cookieParser()
  app.use express.cookieSession(secret: "FIXTHIS")
  # TODO: protect cookie

  auth_user = (req, res, next) ->
    if req.session.id
      next()
    else
      res.json 401, null

  load_user = (req, res, next) ->
    if req.session?.id
      User.find(where: id: req.session.id).done (err, user) ->
        throw err if err
        req.user = user
        next()
    else
      res.json 401, null

  app.post    '/users', (req, res) ->
    user = User.build req.body
    user.password_salt = gen_salt()
    user.password_hash = hash(req.body.password, user.password_salt)
    user.save().done (err, user) ->
      if err
        res.json 401, error: "Can't save user"
      else
        res.json 201, user

  app.put     '/users', (req, res) ->
    User.find(where: pseudo: req.body.pseudo).done (err, user) ->
      if err or user is null or hash(req.body.password, user.password_salt) isnt user.password_hash # do async
        res.json 401, error: "No such alias / password"
      else
        req.session.id = user.id
        res.json 200, user.full()

  app.get     '/users/:id', auth_user, (req, res) ->
    User.find(where: id: req.params.id).done (err, user) ->
      if err or !user
        res.json 401, error: "No such user"
      else
        res.json 200, user.public()

  app.post    '/keys', load_user, (req, res) ->
    key = Key.build req.body
    key.user_id = req.user.id
    User.find(where: id: key.dest_id).done (err, user) ->
      if err or user is null
        res.json 401, error: "Can't find dst"
      else
        key.save().done (err, key) ->
          if err or key is null
            res.json 401, error: "Can't save key"
          else
            res.json key

  app.delete  '/keys/:id', load_user, (req, res) ->
    Key.find(where: id: req.params.id).done (err, key) ->
      if not key or key.user_id isnt req.user.id and key
        res.json 401, error: "Can't find key"
      else
        key.destroy().done (err, key) ->
          if err or key is null
            res.json 401, error: "Can't delete key"
          else
            res.json {}

  #app.delete  '/keys/:id', (req, res) ->

  app.post    '/messages', load_user, (req, res) ->
    message = Message.build req.body
    message.user_id = req.user.id
    Key.find(where: id: message.key_id).done (err, key) ->
      # (check if present in auths)
      if err or not key
        res.json 401, error: "No such key"
      else
        message.save().error((error) ->
          res.json error: "Can't save message"
        ).success (message) ->
          res.json message

  #app.delete  '/msgs/:id', (req, res) ->

  app.get '/reset', (req, res) ->
    User.destroy()
    Key.destroy()
    Message.destroy()
    res.send(200)

  console.log "Listening on 5566"
  app.listen 5566

# database
sequelize = new Sequelize(null, null, null, dialect: 'sqlite', storage: 'development.sqlite')

User = sequelize.import(__dirname + "/models/user")
Key = sequelize.import(__dirname + "/models/key")
Message = sequelize.import(__dirname + "/models/message")

sequelize.sync(force: true).success(->
  console.log("Sync success")
  ready()
).error(->
  console.log "Sync error"
)
