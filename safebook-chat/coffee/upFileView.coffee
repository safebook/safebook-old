BLOCKSIZE = 8096
$ ->
  class window.upFileView extends Backbone.View
    template: _.template $('#upFileTemp').html()

    el: '<div class="msg_app"></div>'

    initialize: (data) ->
      @file = data
      @done = 0
      @reader = new FileReader()

      for event of @socket_events
        socket.on event, @[@socket_events[event]]

      @render()
      socket.emit 'upload', _(@file).pick('name', 'size')

    render: ->
      @$el.html @template(_.extend _(@file).pick('name', 'size'), done: @done)

    send_chunk: =>
      console.log 'send_chunk'
      @start = @done
      @done = Math.min(@start + BLOCKSIZE, @file.size)
      # TODO: native B64 read
      @reader.onloadend = (e) ->
        array = new Uint8Array @result
        bitArray = sjcl.codec.bytes.toBits(array)
        hidden_chunk = Safebook.hide Keys.channel, bitArray
        socket.emit 'chunk', data: sjcl.codec.base64.fromBits hidden_chunk

      @reader.readAsArrayBuffer @file.slice(@start, @done)

    socket_events:
      'upload' : 'on_upload'
      'chunk' : 'on_chunk'

    on_upload: =>
      console.log 'on_upload'
      @send_chunk()

    on_chunk: (data) =>
      console.log 'on_chunk'
      if @done is @file.size
        socket.emit 'upload_end'
        @render()
      else
        @send_chunk()
        @render() # if
