class App.C.Users extends Backbone.View
  constructor: ->
    super
    @template = _.template $('#users_tpl').html()
    App.M.Users.on 'remove', @render
    App.M.Users.on 'add', @add_child
    @

  render: =>
    @$el.html(@template())
    App.M.Users.each((user) =>
      @add_child(user) unless user.get('id') is App.User.get('id')
    )
    @

  add_child: (user) =>
    view = new App.C.User(model: user)
    @$("ul").append(view.render().el)

  events:
    'click    #user_btn':   'fetch_user'
    'keypress #user_input': 'adding_user'

  adding_user: (e) =>
    console.log "keypress"
    @fetch_user() if e.keyCode is 13

  fetch_user: ->
    console.log "fetching..."
    pseudo = $("#user_input").val()
    user = new App.M.User(pseudo: pseudo)
    user.on 'sync', (user) =>
      user.shared()
      App.M.Users.add user.attributes
      App.Dest = user
      App.Home.trigger 'refresh'
    user.fetch()
