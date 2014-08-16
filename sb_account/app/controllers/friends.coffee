Spine = require('spine')

User  = require('models/user')

class Friends extends Spine.Controller
  tag: 'li'

  constructor: (@user) ->
    super
    @render()
    @

  render: ->
    @html require('views/friend')(@user)

  events:
    'click p': 'deroule'

  deroule: =>
    if Friends.selected?
      Friends.selected.$('p').css 'color', ''
    Friends.selected = @
    User.selected_id = @user.id
    @$('p').css 'color', 'red'

module.exports = Friends
