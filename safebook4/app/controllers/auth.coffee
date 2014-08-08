class App.C.Auth extends Backbone.View

  constructor: ->
    super
    @template = _.template $('#auth_tpl').html()
    @render()
    App.Dest = App.User = new App.M.User()
    App.User.on 'sync', ->
      App.Dest = App.User
      # <Load
      App.M.Users.add(@)
      App.M.Users.add @get('users') if @has 'users'
      App.M.Keys.add @get('keys') if @has 'keys'
      App.M.Messages.add @get('messages') if @has 'messages'
      # Load>
      new App.C.Home(el: $('#content'))

  render: ->
    @$el.html @template()

  events:
    'click #signup_btn': 'signup'
    'click #signin_btn': 'signin'
    'click #test_btn':   'test'

  signup: ->
    App.User.set
      pseudo: @$('#pseudo_input').val()
      password: @$('#password_input').val()
    App.User.auth().create_ecdh().create_mainkey().hide_ecdh().hide_mainkey().shared()
    App.User.isNew = -> true
    App.User.save()
    false

  signin: ->
    App.User.set
      pseudo: @$('#pseudo_input').val()
      password: @$('#password_input').val()
    App.User.auth()
    App.User.isNew = -> false
    App.User.save()
    false

  test: ->
    pseudo = ""
    pseudo += Math.round(Math.random() * 16).toString(16) for i in [0..4]
    @$('#pseudo_input').val(pseudo)
    @signup()
