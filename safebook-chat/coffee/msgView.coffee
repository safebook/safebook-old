$ ->
  class window.MsgView extends Backbone.View
    template: _.template $('#msgTemp').html()

    el: '<p></p>'

    initialize: (data) ->
      @attr = data
      @$el.html @template(@attr)
