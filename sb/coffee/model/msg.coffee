#= require spine/spine
#= require spine/ajax

#= require S

class window.Msg extends Spine.Model
  @configure "Msg", "user_id", "key_tag", "value", "data"
  @extend Spine.Model.Ajax

  hide_with: (key) ->
    @data = S.hide_text(key.value, @value)
    @

  bare_with: (key) ->
    @value = S.bare_text(key.value, @data)
    @

  toJSON: ->
    key_tag: @key_tag, user_id: @user_id, data: @data
