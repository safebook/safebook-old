class Entropy
  constructor: ->
    @entropy = 0

    window.addEventListener "load", ((e) => @time_collector(e)), false
    window.addEventListener "mousemove",((e) => @mouse_collector(e)), false
    window.addEventListener "keypress", ((e) => @keys_collector(e)), false

    if window.crypto and window.crypto.getRandomValues
      array = new Uint32Array(32)
      window.crypto.getRandomValues(array)
      @add array, 1024, "getRandomValues"

  add: (value, estimate, source) ->
    @entropy += estimate
    sjcl.random.addEntropy(value, estimate, source)
    $("#entropy").text @entropy

  time_collector: (e) ->
    @add (new Date()).valueOf(), 2, "loadtime"

  mouse_collector: (e) ->
    x = e.x || e.clientX || e.offsetX || 0
    y = e.y || e.clientY || e.offsetY || 0
    @add [x,y], 2, "mouse"

  keys_collector: (e) ->
    ms = new Date().getMilliseconds()
    keyCode = e.keyCode || e.which
    @add [ms, keyCode], 2, "keys"

entropy = new Entropy()
