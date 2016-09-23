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
      'keypress textarea' : 'watch_textarea'
      'change #file': 'send_file'

    watch_textarea: (e) ->
      if (e.keyCode or e.which) is 13 and not e.shiftKey
        @send_message()
        e.preventDefault()

    send_message: ->
      msg = $("textarea").val()
      $("textarea").val ''
      socket.emit 'msg', msg: Safebook.hide_message(Keys.channel, msg)
      @add_message pseudo: @attr.pseudo, msg: msg

    send_file: (e) ->
      file = e.target.files[0]
      $("#messages").prepend (new upFileView(file)).el

    socket_events:
      'asking'    : 'on_asking'
      'accepted'  : 'on_accepted'
      'msg'       : 'on_msg'
      'disconnect': 'on_leaver'
      'joiner'    : 'on_joiner'
      'download'  : 'on_download'
      #'joiner'    : 'on_joiner',
      #'leaver'    : 'on_leaver',

    on_asking: (data) =>
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

    on_download: (data) ->
      $("#messages").prepend (new dlFileView(data)).el

    on_leaver: (data) =>
      temp = "<div class=\"msg_app\"><%- pseudo %> deco</div>"
      $("#messages").prepend(_.template(temp)(data))

    on_joiner: (data) =>
      temp = "<div class=\"msg_app\"><%- pseudo %> join</div>"
      $("#messages").prepend(_.template(temp)(data))
