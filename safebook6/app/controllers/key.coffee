class App.C.Key extends Backbone.View
  constructor: ->
    super
    @template = _.template $('#key_tpl').html()

  render: =>
    @el = $ @template(@model.attributes)
    @

  events:
    'click .key': 'delete_key'
  delete_key: =>
