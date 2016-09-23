#= require spine/spine
#= require spine/ajax

#= require S

class window.Key extends Spine.Model
  @configure "Key", "tag", "user_id", "dest_id", "value", "data"
  @extend Spine.Model.Ajax

  share_to: (friend) ->
    @tag = S.tag()
    key = S.new_key(friend.shared)
    @value = key.value
    @data = key.data
    @

  shared_with: (friend) ->
    @value = S.bare_key(friend.shared, @data)
    @

  toJSON: ->
    tag: @tag, user_id: @user_id, dest_id: @dest_id, data: @data

  @export: ->
    k = 0
    str = "{"
    Key.each (key) ->
      str += "," if k++
      str += '"' + key.tag + '":"' + S.armor(key.value) + '"'
    str + "}"
