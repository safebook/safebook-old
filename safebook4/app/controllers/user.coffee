class App.C.User extends Backbone.View
  constructor: ->
    super
    @template = _.template $('#user_tpl').html()
    @

  render: =>
    @$el = @el = $(@template(@model.attributes))
    @delegateEvents()
    @

  events:
    'click .name': 'select_user'
    'click .send': 'send_key'
    'click .del':  'del_user'

  send_key: ->
    #App.Dest.shared(App.User) unless App.Dest.has 'shared'
    key = new App.M.Key(user: App.User, dest: @model)
    key.generate().on 'sync', =>
      App.M.Keys.push key
    key.save()
    false

  del_user: =>
    App.M.Users.remove(@model)
    false

  select_user: =>
    App.Dest = @model
    App.Home.trigger 'refresh'
    false
