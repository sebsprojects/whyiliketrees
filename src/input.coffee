class window.Input

  constructor: () ->
    @_keys = (false for [1..255])
    $(window).on "keydown", (event) => @handleKeyDown event
    $(window).on "keyup", (event) => @handleKeyUp event


  handleKeyDown: (event) ->
    @_keys[event.keyCode] = true
    #console.log event.keyCode

  handleKeyUp: (event) ->
    @_keys[event.keyCode] = false

  keyPressed: (keyCode) ->
    return @_keys[keyCode]