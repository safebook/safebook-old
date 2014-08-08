class App.C.Messages extends Backbone.View
  constructor: ->
    super
    @template = _.template $('#messages_tpl').html()
    App.M.Messages.on 'remove', @render
    App.M.Messages.on 'add', @add

  render: =>
    @$el.html @template()
    App.M.Messages.each @add
    @

  add: (message) =>
    view = new App.C.Message(model: message)
    @$("ul").append view.render().el

  events:
    'click    #message_btn':   'add_message'

  add_message: ->
    key = App.Dest.keys()[0]
    message = new App.M.Message
      data: $('#message_input').val()
      user: App.User
      key: key
    message.hide().on 'sync', =>
      App.M.Messages.add(message)
    message.save()
