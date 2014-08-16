class App.C.Message extends Backbone.View
  constructor: ->
    super
    @template = _.template $('#message_tpl').html()

  render: =>
    @$el = @el = $(@template(@model.attributes))
    @delegateEvents()
    @
