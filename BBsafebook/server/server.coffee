Sequelize = require 'sequelize'
express   = require 'express'

sequelize = new Sequelize 'database', 'username', 'password',
  dialect: 'sqlite'
  storage: 'db.sqlite'

User = sequelize.define 'User', {
  pseudo:
    type: Sequelize.STRING
    unique: true
  pubkey:
    type: Sequelize.STRING
    unique: true
  email:
    type: Sequelize.STRING
    unique: true
  token:
    type: Sequelize.STRING
    unique: true
  data:
    type: Sequelize.STRING
    unique: true
}, timestamps: false, underscored: true, instanceMethods: {
  public: ->
    Sequelize.Utils._.pick(@, 'pseudo', 'pubkey')
  private: ->
    Sequelize.Utils._.pick(@, 'pseudo', 'pubkey', 'data')
}

Circle = sequelize.define 'Circle', {
  data: Sequelize.STRING
}, timestamps: false, underscored: true

User.hasMany Circle

Auth = sequelize.define 'Auth', {
  data: Sequelize.STRING
  # user_id: Sequelize.INTEGER
  # et/ou
  # circle_id: Sequelize.INTEGER
}, timestamps: false, underscored: true

User.hasMany Auth
Circle.hasMany Auth

app = express()
app.use express.json()

app.use(express.static('/home/max/Clean/join-safebook/public'))

app.get '/', (req, res) ->
  res.redirect('/index.html')

app.post '/users', (req, res) ->
  user = User.build(req.body)
  user.save()
    .success ->
      res.send user.private()
    .error (err) ->
      field = err.message.split(' ')[2]
      if field is 'token' or field is 'pseudo'
        res.send 401, 'Pseudo is already token'
      if field is 'email'
        res.send 401, 'Email is already token'
      if field is 'data' or field is 'pubkey'
        res.send 401, 'Error ! You clicked twice, or you run under very low entropy!'
        # log
      res.send 401

app.get '/users/:pseudo', (req, res) ->
  User.find(where: pseudo: req.params.pseudo).success (user) ->
    if user?
      res.send user.public()
    else
      res.send 404, {}

User.sync()
  .error ->
    console.error "Can't sync User"
  .success -> Circle.sync()
    .error ->
      console.error "Can't sync Circle"
    .success -> Auth.sync()
      .error ->
        console.error "Can't sync Auth"
      .success ->
        console.log "Sync ok"
        app.listen 8000
