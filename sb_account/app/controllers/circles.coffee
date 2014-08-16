Spine = require('spine')

I = require('models/i')
Circle = require('models/circle')
User = require('models/user')
Key = require('models/key')
Friends = require('controllers/friends')

class Circles extends Spine.Controller
  tag: 'li'

  constructor: (@circle) ->
    super
    console.log "render "
    console.log @circle.name
    @render()

  render: ->
     @html require('views/circle')(name: @circle.name)

  elements:
    '.more': 'more'

  events:
    'click p': 'deroule'

  deroule: =>
    if Friends.selected
      present = false
      for item in User.find(User.selected_id).items
        present = true if item is @user.id
      Key.create(circle_id: @circle.id, user_id: I.id, dest_id: User.selected_id) unless present

    Circles.selected?.render()
    Circles.selected = @

    @more.html ''
    for id in Circle.find(@circle.id).items
      @more.append '<li>' + User.find(id).pseudo + '</li>'

module.exports = Circles
