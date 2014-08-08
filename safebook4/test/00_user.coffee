logins = ->
  pseudo: 'test_' + Math.floor(Math.random() * 10000000).toString()
  password: Math.floor(Math.random() * 100000000000).toString()

describe "A user basics", () ->

  beforeEach ->
    App.User = new App.Model.User()
    App.Dest = new App.Model.User()
    App.Collection.Users = new _Users()
    App.Collection.Keys = new _Users()
    App.Collection.Messages = new _Users()

  it "auth", ->
    App.User.set(logins()).auth()

  it "create and hide and bare keys", ->
    App.User.set(logins()).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey()#.create_key()

  it "is saved then fetched", (done) ->
    login = logins()
    App.User.set(login).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey()#.create_key()
    App.User.isNew = -> true
    App.User.on 'sync', ->
      user = new App.Model.User()
      user.set(login).auth()
      user.isNew = -> false
      user.on 'sync', ->
        #user.bare_ecdh()#.bare_key()
        #expect(App.User.get('seckey').limbs).toEqual(user.get('seckey').limbs)
        done()
      user.save()
    App.User.save()
