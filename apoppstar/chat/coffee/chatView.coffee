$ ->
  class window.ChatView extends Backbone.View

    template: _.template $('#chatTemp').html()

    el: $ 'body'

    initialize: (data) ->
      @attr = data
      for event of @socket_events
        socket.on event, @[@socket_events[event]]

      @$el.html @template(@attr)

    add_message: (attr) ->
      $("#messages").prepend (new MsgView(attr)).el

    add_invite: (attr) ->
      $("#messages").prepend (new AskView(attr)).el

    events:
      'click button' : 'send_message'

    send_message: ->
      msg = $("textarea").val()
      $("textarea").val ''
      socket.emit 'msg', msg: Safebook.hide_message(Keys.channel, msg)
      @add_message pseudo: @attr.pseudo, msg: msg

    socket_events:
      'ask'       : 'on_ask'
      'accepted'  : 'on_accepted'
      'msg'       : 'on_msg'
      'disconnect': 'on_leaver'
      'joiner'    : 'on_joiner'
      #'joiner'    : 'on_joiner',
      #'leaver'    : 'on_leaver',

    on_ask: (data) =>
      shared = Safebook.get_shared_key(Keys.seckey, data.pubkey)
      @add_invite pseudo: data.pseudo, shared: shared

    on_accepted: (data) ->
      console.log "accepted"
      Keys.shared = Safebook.get_shared_key(Keys.seckey, data.pubkey)
      Keys.channel = Safebook.decrypt_key(Keys.shared, data.hidden_key)
      $("#messages").prepend($('<div class="msg_app">Your now in</div>'))

    on_msg: (data) =>
      data.msg = Safebook.load_message(Keys.channel, data.msg)
      @add_message data

    on_leaver: (data) =>
      $("#messages").prepend($("<div class=\"msg_app\">#{data.pseudo} deco</div>"))

    on_joiner: (data) =>
      $("#messages").prepend($("<div class=\"msg_app\">#{data.pseudo} join</div>"))
