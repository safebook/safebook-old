logins = ->
  pseudo: 'test_' + Math.floor(Math.random() * 10000000).toString()
  password: Math.floor(Math.random() * 100000000000).toString()

describe "A social user", ->

  beforeEach ->
    App.User = new App.Model.User()
    App.Dest = new App.Model.User()
    App.Collection.Users = new _Users()
    App.Collection.Keys = new _Keys()
    App.Collection.Messages = new _Messages()

  login3 = logins()
  login4 = logins()

  it "can send a message on a key he control", (done) ->
    App.User.set(login3).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey()
    App.User.isNew = -> true

    user = new App.Model.User()
    user.set(login4).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey()
    user.isNew = -> true

    App.User.shared(user)
    user.shared(App.User)

    App.User.on 'sync', ->
      user.on 'sync', ->
        key = new App.Model.Key()
        key.generate(user).on 'sync', ->
          message = new App.Model.Message( data: "my message data" )
          message.hide(key).on 'sync', done
          message.save()
        key.save()
      user.save()
    App.User.save()

  it "get his messages back", (done) ->
    App.User.set(login3).auth()
    App.User.isNew = -> false

    user = new App.Model.User()
    user.set(login4).auth()
    user.isNew = -> false

    App.User.on 'sync', ->
      user.on 'sync', ->
        App.User.shared(user)
        user.shared(App.User)
        key = App.Collection.Keys.first().bare(user)
        message = App.Collection.Messages.first().bare(key)
        expect(message.get('data')).toEqual("my message data")
        done()
      user.save()
    App.User.save()
