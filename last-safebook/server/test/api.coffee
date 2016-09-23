crypto  = require 'crypto'
_       = require 'lodash'
request = require 'supertest'

url = 'http://0.0.0.0:5566'

urlencode = (str) ->
  str.replace(/\+/g, '-').replace(/\//g, '_').replace(/\=/g, '')

random_user = (attrs) ->
  _.merge (
    id: urlencode crypto.pseudoRandomBytes(8).toString 'base64'
    pseudo: crypto.pseudoRandomBytes(8).toString 'base64'
    password: crypto.pseudoRandomBytes(16).toString 'base64'
    pubkey: crypto.pseudoRandomBytes(256).toString 'base64'
    data: crypto.pseudoRandomBytes(1024).toString 'base64'
  ), (attrs || {})

random_key = (attrs) ->
  _.merge (
    id: urlencode crypto.pseudoRandomBytes(64).toString 'base64'
    data: crypto.pseudoRandomBytes(512).toString 'base64'
  ), (attrs || {})

random_message = (attrs) ->
  _.merge (
    data: crypto.pseudoRandomBytes(512).toString 'base64'
  ), (attrs || {})

user = random_user()
public_user = _.pick user, 'id', 'pseudo', 'pubkey'
login = _.pick user, 'pseudo', 'password'
user2 = random_user()
login2 = _.pick user2, 'pseudo', 'password'
user3 = random_user()
login3 = _.pick user3, 'pseudo', 'password'

describe 'api', ->

  before (done) ->
    request(url).get('/reset').expect(200).end(done)

  before (done) ->
    request(url).post('/users').send(user).expect(201).end(done)

  before (done) ->
    request(url).post('/users').send(user2).expect(201).end(done)

  before (done) ->
    request(url).post('/users').send(user3).expect(201).end(done)


  describe 'users', ->

    describe '#create', ->

      it 'work if user is valid', (done) ->
        request(url).post('/users').send(random_user()).expect(201).end(done)

      it 'fail if no pseudo', (done) ->
        tuser = random_user()
        delete tuser.pseudo
        request(url).post('/users').send(tuser).expect(401).end(done)

      it 'fail if pseudo is not unique', (done) ->
        tuser = random_user()
        tuser2 = random_user(pseudo: tuser.pseudo)
        request(url).post('/users').send(tuser).expect(201).end ->
          request(url).post('/users').send(tuser2).expect(401).end(done)

      it 'fails if pubkey is not unique', (done) ->
        tuser = random_user()
        tuser2 = random_user(pubkey: tuser.pubkey)
        request(url).post('/users').send(tuser).expect(201).end ->
          request(url).post('/users').send(tuser2).expect(401).end(done)

      it 'work only if pseudo length is between 2 and 16', (done) ->
        tuser1 = random_user(pseudo: '1')
        tuser2 = random_user(pseudo: '12')
        tuser16 = random_user(pseudo: '1234567890123456')
        tuser17 = random_user(pseudo: '12345678901234567')
        request(url).post('/users').send(tuser1).expect(401).end -> # missing check cause
          request(url).post('/users').send(tuser2).expect(201).end -> # bad end comportement
            request(url).post('/users').send(tuser16).expect(201).end ->
              request(url).post('/users').send(tuser17).expect(401).end(done)

      # check password, pubkey, data is base64, (mini/maxi length)
      # dont check password unicity because salted and hashed (?)
      # don't check data unicity because useless and may be bad used (?)

    # WARN : TODO use secure session

    describe '#login', ->

      it 'fail if login password is invalid', (done) ->
        login_fail = _.pick login, 'pseudo'
        login_fail.password = "bad password"
        request(url).put('/users').send(login_fail).expect(401).end(done)

      it 'work if login is valid', (done) ->
        request(url).put('/users').send(login).expect(200).end(done)

      it 'return the full user', (done) ->
        request(url).put('/users').send(login).expect(200).expect(_.omit user, 'password').end(done)

    describe '#read', ->

      it 'fail if the user isnt logged', (done) ->
        request(url).get('/users/'+user.id).expect(401).end(done)

      it 'fail if the user failed to log', (done) ->
        login_fail = _.pick user, 'pseudo'
        login_fail.password = "bad password"
        request(url).put('/users').send(login_fail).expect(401).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          request(url).get('/users/'+user.id).set('cookie', cookie).expect(401).end(done)

      it 'work and get only the restricted values if user is logged', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          request(url).get('/users/'+user.id).set('cookie', cookie).expect(200).expect(public_user).end(done)

  describe 'Keys', ->

    describe "#create", ->

      it 'work if user and dest are valid', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          key = random_key(dest_id: user2.id)
          request(url).post('/keys').set('cookie', cookie).send(key).expect(200).end(done)

      it 'fail unless logged', (done) ->
        key = random_key(dest_id: user2.id)
        request(url).post('/keys').send(key).expect(401).end(done)

      it 'dont work if dest is invalid', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          key = random_key(dest_id: random_user().id)
          request(url).post('/keys').set('cookie', cookie).send(key).expect(401).end(done)

    describe "#delete", ->

      it 'work if user and key are valid', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          key = random_key(dest_id: user2.id)
          request(url).post('/keys').set('cookie', cookie).send(key).expect(200).end (err, res) ->
            throw err if err
            request(url).del('/keys/' + key.id).set('cookie', cookie).expect(200).end(done)

      it 'fail if user isnt key creator', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          key = random_key(dest_id: user2.id)
          request(url).post('/keys').set('cookie', cookie).send(key).expect(200).end (err, res) ->
            throw err if err
            request(url).put('/users').send(login2).expect(200).end (err, res) ->
              cookie = res.headers['set-cookie']
              request(url).del('/keys/' + key.id).set('Cookie', cookie).expect(401).end(done)

      it 'fail without the cookie', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          key = random_key(dest_id: user2.id)
          request(url).post('/keys').set('cookie', cookie).send(key).expect(200).end (err, res) ->
            throw err if err
            request(url).del('/keys/' + key.id).expect(401).end(done)

  describe 'Messages', ->

    describe '#create', ->

      it 'fail unless logged', (done) ->
        message = random_message(key_id: random_key().id)
        request(url).post('/messages').send(message).expect(401).end(done)

      it 'fail unless linked to a valid key', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          message = random_message(key_id: random_key().id)
          request(url).post('/messages').send(message).expect(401).end(done)

      it 'work if user and key are valid (with the key creator)', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          key = random_key(dest_id: user2.id)
          request(url).post('/keys').set('cookie', cookie).send(key).expect(200).end (err, res) ->
            throw err if err
            request(url).put('/users').send(login2).expect(200).end (err, res) ->
              throw err if err
              message = random_message(key_id: key.id)
              request(url).post('/messages').set('cookie', cookie).send(message).expect(200).end(done)

      it 'work if user and key are valid (with the key possessor)', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          key = random_key(dest_id: user2.id)
          request(url).post('/keys').set('cookie', cookie).send(key).expect(200).end (err, res) ->
            throw err if err
            request(url).put('/users').send(login2).expect(200).end (err, res) ->
              throw err if err
              message = random_message(key_id: key.id)
              request(url).post('/messages').set('cookie', cookie).send(message).expect(200).end(done)

      it 'fail if user isnt key follower', (done) ->
        request(url).put('/users').send(login).expect(200).end (err, res) ->
          throw err if err
          cookie = res.headers['set-cookie']
          key = random_key(dest_id: user2.id)
          request(url).post('/keys').set('cookie', cookie).send(key).expect(200).end (err, res) ->
            throw err if err
            request(url).put('/users').send(login3).expect(200).end (err, res) ->
              throw err if err
              message = random_message(key_id: key.id)
              request(url).post('/messages').set('cookie', cookie).send(message).expect(401).end(done)

          # describe can't get non existing user without session
          # describe can't get non existing user with session
