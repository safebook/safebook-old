#= require spine/spine
#= require spine/ajax

#= require S

class window.Contact extends Spine.Model
  @configure "Contact", "id", "pseudo", "pubkey", "shared"
  @extend Spine.Model.Ajax

  url: ->
    if @id? then 'users/' + @id else 'users'

  get_shared: (seckey) =>
    @shared = S.get_shared(seckey, @pubkey)
    console.log @shared
