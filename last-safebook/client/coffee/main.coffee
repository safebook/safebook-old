Backbone = require("backbone")
_ = require("underscore")

ecdh_keys = ->
  r = undefined
  r = {}

Class User extends Backbone.Model
  toJSON: ->
    _.pick @attributes, "id", "pseudo", "password", "pubkey", "data"

  getKeys: ->
    Keys.where user_id: @get("id")

class Users extends Backbone.Collection
  model: User
  getKeys: ->
    Keys.where user_id: @id

class Key extends Backbone.Model
  toJSON: ->
    _.pick @attributes, "id", "user_id", "dest_id", "data"

  getMessages: ->
    Messages.where key_id: @get("id")

  Key

class Keys extends Backbone.Collection
  model: Key

class Message extends Backbone.Model
  toJSON: ->
    _.pick @attributes, "id", "user_id", "key_id", "data"

  getKey: ->
    Keys.find @get("key_id")

  getUser: ->
    Users.find @get("user_id")

class Messages extends Backbone.Collection
  model: Message

Users = new Users()
Keys = new Keys()
Messages = new Messages()

describe "users", ->
  Users.add
    id: "firstID"
    pseudo: "firstPseudo"
    pubkey: "firstPubkey"
    password: ""
  Users.add
    id: "secondID"
    pseudo: "secondPseudo"
    pubkey: "secondPubkey"

  Users.add
    id: "ID3"
    pseudo: "Pseudo3"
    pubkey: "Pubkey3"

  Users.add
    id: "ID4"
    pseudo: "Pseudo4"
    pubkey: "Pubkey4"

  it "contains 4 users", ->
    expect(Users.toArray().length).toBe 4


describe "keys", ->
  Keys.add
    id: "keyID1"
    user_id: "firstID"
    dest_id: "firstID"
    data: ""

  Keys.add
    id: "keyID2"
    user_id: "firstID"
    dest_id: "secondID"
    data: ""

  Keys.add
    id: "keyID3"
    user_id: "ID3"
    dest_id: "secondID"
    data: ""

  Keys.add
    id: "keyID4"
    user_id: "ID3"
    dest_id: "secondID"
    data: ""

  it "contains 4 keys", ->
    expect(Keys.toArray().length).toBe 4

  it "can be pick by a user", ->
    expect(Users.find("firstID").getKeys().length).toBe 2
    expect(Users.find("ID3").getKeys().length).toBe 2

describe "messages", ->
  Messages.add [
    id: "keyMsg1"
    user_id: "firstID"
    content: "Hello :)"
  ]
  Messages.add [
    id: "keyMsg2"
    key_id: "keyID1"
    user_id: "secondID"
    content: "Hello :)"
  ]
  Messages.add [
    id: "keyMsg2"
    key_id: "keyID2"
    user_id: "firstID"
    content: "Hello 2 :)"
  ]
  Messages.add [
    id: "keyMsg2"
    key_id: "keyID3"
    user_id: "ID3"
    content: "Hello 2 :)"
  ]
  Messages.add [
    id: "keyMsg4"
    key_id: "keyID4"
    user_id: "ID3"
    content: "44 2 :)"
  ]
  Messages.add [
    id: "keyMsg3"
    key_id: "keyID4"
    user_id: "ID3"
    content: "44 2 :)"
  ]

console.log Users.toArray()
console.log Keys.toArray()
console.log Messages.toArray()
console.log "live"
Users.each (user) ->
  console.log user.id
  console.log user.getKeys()
  _.each user.getKeys(), (key) ->
    console.log key.getMessages()


console.log "All keys"
console.log Keys.toArray()
console.log "All messages"
console.log Messages.toArray()
window.Keys = Keys
