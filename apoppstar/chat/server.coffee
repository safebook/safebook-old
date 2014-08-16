express = require('express')
app     = express()
server  = require('http').createServer(app)
io      = require('socket.io').listen(server)

rooms = []
server.listen(8004)

app.use '/js', express.static(__dirname + '/src/js')

app.get '/main.css', (req, res) ->
  res.sendfile(__dirname + '/src/main.css')

app.get '/*', (req, res) ->
  res.sendfile(__dirname + '/src/index.html')

io.configure 'production', ->
  io.set('log level', 0)

io.sockets.on 'connection', (socket) ->
  room      = null
  pseudo    = null

  socket.on 'register', (data) ->
    unless data.pubkey?
      socket.emit 'registered', ok: false, error: 'no pubkey'
    unless data.pseudo?
      socket.emit 'registered', ok: false, error: 'no pseudo'
    else if rooms[socket.id]?
      socket.emit 'registered', ok: false, error: 'a room with this id already exist'
    else
      room      = socket.id
      pseudo    = data.pseudo
      accepted  = true
      socket.join room
      rooms[room] = pubkey: data.pubkey, clients: {}
      rooms[room].clients[pseudo] = id: socket.id, in: true
      socket.emit 'registered', ok: true, room: room

  socket.on 'ask', (data) ->
    unless data.pubkey?
      socket.emit 'asked', ok: false, error: 'no pubkey'
    unless data.pseudo?
      socket.emit 'asked', ok: false, error: 'no pseudo'
    else unless data.room? and rooms[data.room]?
      socket.emit 'asked', ok: false, error: 'no room with this id'
    else if rooms[data.room].clients[data.pseudo]?
      socket.emit 'asked', ok: false, error: 'pseudo already taken'
    else
      room      = data.room
      pseudo    = data.pseudo
      rooms[room].clients[pseudo] = id: socket.id
      io.sockets.socket(room).emit 'ask', pseudo: pseudo, ip: socket.handshake.address.address, pubkey: data.pubkey
      socket.emit 'asked', ok: true

  socket.on 'confirm', (data) ->
    unless room? and rooms[room]? and room is socket.id
      socket.emit 'confirmed', ok: false, error: 'don\'t own a room'
    else unless data.hidden_key?
      socket.emit 'confirmed', ok: false, error: 'no hidden_key'
    else unless data.pseudo?
      socket.emit 'confirmed', ok: false, error: 'no pseudo'
    else unless rooms[room].clients[data.pseudo]?
      socket.emit 'confirmed', ok: false, error: 'nobody with this pseudo'
    else
      rooms[room].clients[data.pseudo].in = true
      client = io.sockets.socket(rooms[room].clients[data.pseudo].id)
      client.join room
      client.emit 'accepted', hidden_key: data.hidden_key, pubkey: rooms[room].pubkey
      client.broadcast.to(room).emit 'joiner', pseudo: data.pseudo
      socket.emit 'confirmed', ok: true

  socket.on 'msg', (data) ->
    console.log "debug"
    unless room? and rooms[room]? and rooms[room].clients[pseudo].in?
      socket.emit 'msg error'
    else
      socket.broadcast.to(room).emit 'msg', pseudo: pseudo, msg: data.msg

  socket.on 'disconnect', ->
    if room? and pseudo?
      if rooms[room].clients[pseudo].in?
        io.sockets.in(room).emit 'disconnect', pseudo: pseudo
      delete rooms[room].clients[pseudo]
      delete rooms[room] if io.sockets.clients(room).length is 0
