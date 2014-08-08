logins = ->
  pseudo: 'test_' + Math.floor(Math.random() * 10000000).toString()
  password: Math.floor(Math.random() * 100000000000).toString()

describe "A crypto user", ->

  beforeEach ->
    App.User = new App.Model.User()
    App.Dest = new App.Model.User()
    App.Collection.Users = new _Users()
    App.Collection.Keys = new _Keys()
    App.Collection.Messages = new _Messages()

  it "create a shared secret with someone else", ->
    App.User.create_ecdh()
    App.Dest.create_ecdh()

    App.User.shared(App.Dest)
    App.Dest.shared(App.User)
    expect(App.User.get('shared')).toEqual(App.Dest.get('shared'))

  key_data = 0
  login = logins()
  login2 = logins()

  it "send a key to someone else", (done) ->
    App.User.set(login).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey()
    App.User.isNew = -> true

    user = new App.Model.User()
    user.set(login2).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey()
    user.isNew = -> true

    App.User.shared(user)
    user.shared(App.User)

    App.User.on 'sync', ->
      user.on 'sync', ->
        key = new App.Model.Key()
        key.generate(user).on 'sync', done
        key_data = key.get('data')
        key.save()
      user.save()
    App.User.save()

  it "get his keys back", (done) ->
    App.User.set(login).auth()
    App.User.isNew = -> false

    user = new App.Model.User()
    user.set(login2).auth()
    user.isNew = -> false

    App.User.on 'sync', ->
      user.on 'sync', ->
        App.User.shared(user)
        user.shared(App.User)
        key = App.Collection.Keys.first().bare(user)
        expect(key.get('data')).toEqual(key_data)
        done()
      user.save()
    App.User.save()
