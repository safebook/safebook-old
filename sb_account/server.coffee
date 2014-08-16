fs = require 'fs'

express = require('express')
app     = express()
server  = require('http').createServer(app)

server.listen(8000)

app.use '/', express.static(__dirname + '/public')
app.get '/', (req, res) ->
  res.redirect '/index.html'
