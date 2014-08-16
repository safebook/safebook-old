$ ->
  class window.LoadView extends Backbone.View

    template: _.template $('#loadTemp').html()

    el: $ 'body'

    initialize: ->
      @$el.html @template()
      for event of @socket_events
        socket.on event, @[@socket_events[event]]
      Entropy.refresh = (value) ->
        $('#randomness').text value

    events:
      'click #hash_file'  : 'select_file',
      'change #file'      : 'hash_file',
      'click #start'      : 'start_chat'

    select_file: ->
      $('#file').click()
      false

    hash_file: (e) ->
      file = e.target.files[0]
      hash_file file, (hash) =>
        console.log sjcl.codec.hex.fromBits hash
        Entropy.add hash, 256, "hash"

    start_chat: =>
      Keys = Safebook.ecdh()
      @pseudo = $("#pseudo").val()
      @room = document.location.pathname.slice(1)
      if @room is ''
        socket.emit 'register', pseudo: @pseudo, pubkey: Keys.pubkey
      else
        socket.emit 'ask', room: @room, pseudo: @pseudo, pubkey: Keys.pubkey
      false

    socket_events:
      'registered' : 'create_chat',
      'asked' : 'wait_for_chat'

    create_chat: (data) =>
      if data.ok
        @room = data.room
        Keys.channel = sjcl.random.randomWords(8)
        View = new ChatView(pseudo: @pseudo, room: @room)
      else
        alert "error: " + data.error

    wait_for_chat: (data) =>
      if data.ok
        View = new ChatView(pseudo: @pseudo, room: @room, waiting: true)
      else
        alert "error: " + data.error
