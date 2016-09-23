express = require('express')
app     = express()
server  = require('http').createServer(app)
io      = require('socket.io').listen(server)

rooms = []
server.listen(22977)

app.use '/js', express.static(__dirname + '/src/js')

app.get '/main.css', (req, res) ->
  res.sendfile(__dirname + '/src/main.css')

app.get '/*', (req, res) ->
  res.sendfile(__dirname + '/src/index.html')

#io.set('log level', 0)

io.sockets.on 'connection', (socket) ->
  room      = null
  pseudo    = null
  sending_file  = null

  socket.on 'create', (data) ->
    unless data.pubkey? and data.pseudo? # + isString isValid
      socket.emit 'create', ok: false, error: 'no pubkey or no pseudo'
    else if rooms[socket.id]?
      socket.emit 'create', ok: false, error: 'this room already exist'
    else
      room      = socket.id
      pseudo    = data.pseudo
      accepted  = true
      socket.join room
      rooms[room] = pubkey: data.pubkey, clients: {}
      rooms[room].clients[pseudo] = id: socket.id, in: true
      socket.emit 'create', ok: true, room: room

  socket.on 'ask', (data) ->
    unless data.pubkey? and data.pseudo? # + isString isValid
      socket.emit 'ask', ok: false, error: 'no pubkey or no pseudo'
    else unless data.room? and rooms[data.room]?
      socket.emit 'ask', ok: false, error: 'no room with this id'
    else if rooms[data.room].clients[data.pseudo]?
      socket.emit 'ask', ok: false, error: 'pseudo already taken'
    else
      room      = data.room
      pseudo    = data.pseudo
      rooms[room].clients[pseudo] = id: socket.id
      io.sockets.socket(room).emit 'asking', pseudo: pseudo, ip: socket.handshake.address.address, pubkey: data.pubkey
      socket.emit 'ask', ok: true

  socket.on 'upload', (data) ->
    if sending_file
      socket.emit 'upload', ok: false
    else
      sending_file = true
      socket.emit 'upload', ok: true
      socket.broadcast.to(room).emit 'download', pseudo: pseudo, name: data.name, size: data.size

  socket.on 'chunk', (data) ->
    socket.broadcast.to(room).emit 'chunk', data
    #setTimeout
    socket.emit 'chunk'

  socket.on 'upload_end', (data) ->
    socket.broadcast.to(room).emit 'dl_end'

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
