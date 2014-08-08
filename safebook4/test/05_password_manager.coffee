logins = ->
  pseudo: 'test_' + Math.floor(Math.random() * 10000000).toString()
  password: Math.floor(Math.random() * 100000000000).toString()

describe "Password manager", ->

  beforeEach ->
    App.User = new App.Model.User()
    App.Dest = new App.Model.User()
    App.Collection.Users = new _Users()
    App.Collection.Keys = new _Keys()
    App.Collection.Messages = new _Messages()
    App.Collection.Passwords = new _Passwords()

  it "can hide and bare", ->
    App.User.set(logins()).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey()
    password = new App.Model.Password()
    password.set url: "facebook.com"
    password.set password: "meegere"
    password.hide().bare() # test values :)
