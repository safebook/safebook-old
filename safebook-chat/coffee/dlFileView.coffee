$ ->
  class window.dlFileView extends Backbone.View
    template: _.template $('#dlFileTemp').html()

    initialize: (data) ->
      @data = data
      @data.bytes = []
      @data.finished = false
      @done = 0
      for event of @socket_events
        socket.on event, @[@socket_events[event]]

      @render()

    events:
      'click a' : 'download'

    download: =>
      base64_file = sjcl.codec.base64.fromBits @data.bytes
      a = document.createElement('a')
      a.setAttribute 'href', "data:application/octet-stream;base64,#{base64_file}"
      a.setAttribute 'download', @data.name

      clickEvent = document.createEvent "MouseEvent"
      clickEvent.initMouseEvent "click", true, true, window, 0,
        null,null,null,null,null,null,null,null, 0, null

      a.dispatchEvent clickEvent

    render: ->
      @$el.html @template(_.extend _(@data).pick('name', 'size', 'finished'), done: @done)
      console.log @data.finished

    socket_events:
      'chunk' : 'on_chunk'
      'dl_end'   : 'on_dl_end'

    on_chunk: (data) =>
      hidden_chunk = sjcl.codec.base64.toBits data.data
      next = Safebook.bare Keys.channel, hidden_chunk
      @data.bytes = sjcl.bitArray.concat @data.bytes, next
      @done = sjcl.bitArray.bitLength(@data.bytes) / 8
      @render()

    on_dl_end: =>
      @data.finished = true
      @render()
