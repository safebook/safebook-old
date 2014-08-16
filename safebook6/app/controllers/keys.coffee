class App.C.Keys extends Backbone.View
  constructor: ->
    super
    @template = _.template $('#keys_tpl').html()
    @render()
    App.M.Keys.on 'add', @add
    @

  render: =>
    @$el.html @template()
    @$("ul").empty()
    App.M.Keys.each @add
    @

  add: (model) =>
    view = new App.C.Key(model: model)
    el = view.render().el
    @$("ul").append($(el))
