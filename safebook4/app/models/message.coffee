class App.M.Message extends Backbone.Model
  urlRoot: '/messages'

  toJSON: ->
    @set user_id: @get('user').get('id') unless @has('user_id')
    @set key_id: @get('key').get('id') unless @has('key_id')
    _.pick @attributes, "id", "user_id", "key_id", "hidden_data"

  constructor: ->
    super
    @set user: App.M.Users.findWhere(id: @get('user_id')) if @has 'user_id'
    @set key: App.M.Keys.findWhere(id: @get('key_id')) if @has 'key_id'
    @bare() if @has('hidden_data') and not @has('data')

  hide: =>
    @set hidden_data: App.S.hide_text(@get('key').get("data"), @get('data'))

  bare: =>
    @set data: App.S.bare_text(@get('key').get("data"), @get('hidden_data'))

  #key: ->
  #  App.M.Keys.findWhere id: @get('key_id')

class _Messages extends Backbone.Collection
  model: App.M.Message

#  involving: (pseudo) ->
#    keys = App.M.Key.select (key) ->
#      key.get('user_id') is pseudo or key.get('dest_id') is pseudo
#
#    @select (message) ->
#      for key in keys
#        return true if key.get('id') is message.get('key_id')
#    false

App.M.Messages = new _Messages()
