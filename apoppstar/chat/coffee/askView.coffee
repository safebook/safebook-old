$ ->
  class window.AskView extends Backbone.View
    template: _.template $('#askTemp').html()

    el: '<div class="msg_app"></div>'

    initialize: (data) ->
      @attr = data
      @$el.html @template(@attr)
      #@delegateEvents()

    events: 'click a' : 'accept'

    accept: ->
      socket.emit 'confirm', pseudo: @attr.pseudo, hidden_key:
        Safebook.encrypt_key(@attr.shared, Keys.channel)

      # to change (ex: askOkTemp)
      @$el.html '<div class="msg_app">'+@attr.pseudo+' accepted</div>'
      false
