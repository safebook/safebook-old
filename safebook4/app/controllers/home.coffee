class App.C.Home extends Backbone.View

  constructor: ->
    super
    App.Home = @
    App.socket = io('http://0.0.0.0:5555')
    App.socket.on 'update', (data) ->
      console.log "update"
      console.log data
      App.M.Users.push(user) for user in data.users
      App.M.Keys.push(key) for key in data.keys
      App.M.Messages.push(message) for message in data.messages
    @template = _.template $('#home_tpl').html()
    @render()
    @on 'refresh', @render
    @

  render: =>
    @$el.html @template()
    (new App.C.Users(el: $('#users'))).render()
    (new App.C.Keys(el: $('#keys'))).render()
    (new App.C.Messages(el: $('#messages'))).render()

  events:
    'click #add_user_key': 'send_user_key'
    'click #select_user':  'select_user'
    'click #logout':      'logout'

  send_user_key: =>
    key = new App.M.Key(user: App.User, dest: App.Dest)
    key.generate().on 'sync', =>
      App.M.Keys.push key
    key.save()

  select_user: =>
    App.Dest = App.User
    @render()

  logout: =>
    # Clear
    # App.M.Users
    # App.M.Keys
    # App.M.Messages
    false

###
  add_group: ->
    group = new App.M.Group(
      name: $('#group_input').val()
    )
    App.User.shared(App.User) unless App.User.has 'shared' #remove when mainkey is set
    group.generate(App.User).on 'sync', =>
      App.M.Groups.add(group)
      @render()
    group.save()
###
