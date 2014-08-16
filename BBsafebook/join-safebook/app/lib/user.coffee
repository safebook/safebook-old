server = "http://0.0.0.0:4567"

class User extends Backbone.Model

  urlRoot: "#{server}/users"

  idAttribute: 'pseudo'

  toJSON: -> @omit 'secret', 'seckey'

  @if_exist: (pseudo, callback) ->
    user = new User pseudo: pseudo
    user.on "sync", callback
    user.fetch()
