class App.M.Key extends Backbone.Model
  urlRoot: '/keys'

  toJSON: ->
    @set_id_from_users()
    @pick "id", "user_id", "dest_id", "hidden_data"

  constructor: ->
    super
    @get_users_from_id()
    @compute_tag() if @has('hidden_data') and not @has('tag')
    @bare() if @has('hidden_data') and not @has('data')

  set_id_from_users: ->
    @set user_id: @get('user').get('id') unless @has('user_id')
    @set dest_id: @get('dest').get('id') unless @has('dest_id')

  get_users_from_id: ->
    @set user: App.M.Users.findWhere(id: @get('user_id')) if @has 'user_id'
    @set dest: App.M.Users.findWhere(id: @get('dest_id')) if @has 'dest_id'

  get_shared: ->
    if @get('dest').get('id') isnt App.User.get('id')
      @get('dest').get('shared')
    else
      @get('user').get('shared')

  generate: (user) ->
    @set
      data: sjcl.random.randomWords(8)
      user_id: @get('user_id')
      dest_id: @get('dest_id')

    # log
    console.log 'data:' + to_b64 @get('data')
    console.log 'key:' + to_b64 @get_shared()

    hidden_data = App.S.hide(@get_shared(), @get('data'))
    @set hidden_data: hidden_data

    # log
    console.log 'hidden:' + @get('hidden_data')

    @compute_tag()

  compute_tag: ->
    @set tag: to_hex(sjcl.bitArray.bitSlice(from_b64(@get('hidden_data')), 0, 32))
    @

  bare: ->
    # log
    console.log 'hidden:' + @get('hidden_data')
    console.log 'key:' + to_b64 @get_shared()

    @set data: App.S.bare(@get_shared(), @get('hidden_data'))

    # log
    console.log 'data:' + to_b64 @get('data')

    @log()

  log: =>
    b64 = (v) -> if v then to_b64(v) else v
    console.log """KEY (#{@get('tag')}) ::
user(#{@get('user').get('id')}) w/ (#{b64(@get('user').get('shared'))})
dest(#{@get('dest').get('id')}) w/ (#{b64(@get('dest').get('shared'))})
hidden_data(#{@get('hidden_data')})
data(#{b64 @get('data')})
"""
    @

class _Keys extends Backbone.Collection
  model: App.M.Key

  from: (user_id) -> @where user_id: user_id
  to:   (dest_id) -> @where dest_id: dest_id

App.M.Keys = new _Keys()
