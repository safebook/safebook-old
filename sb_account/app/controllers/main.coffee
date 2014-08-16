Spine = require('spine')

Circle  = require('models/circle')
Circles = require('controllers/circles')
User    = require('models/user')
Friends = require('controllers/friends')
Key     = require('models/key')
I       = require('models/i')

class Main extends Spine.Controller
  constructor: () ->
    super

    Circle.bind 'reset', =>
      Circle.each (circle) =>
        circle.view.el.html('')

    Circle.bind 'create', (circle) =>
      circle.view = new Circles(circle.toJSON())
      @circles.append circle.view.el

    Key.bind 'create', (key) =>
      User.each (user) =>
        if key.user_id is I.id and key.dest_id is user.id
          if key.circle_id
            circle = Circle.find(key.circle_id)
            circle.items.push(key.dest_id)
          else
            @friends.append (new Friends(user.toJSON())).el


    User.bind 'create', (user) =>
      Key.each (key) =>
        if key.user_id is I.id and key.dest_id is user.id
          if key.circle_id
            circle = Circle.find(key.circle_id)
            circle.items.push(key.dest_id)
          else
            @friends.append (new Friends(user.toJSON())).el


    @html require('views/list')()
    data = require 'data/test'

    Circle.create(circle) for circle in data.circles
    Key.create(key) for key in data.keys
    User.create(user) for user in data.users

  elements:
    '#circles': 'circles'
    '#friends': 'friends'

  events:
    'click #add_friend': 'add_friend'
    'click #add_circle': 'add_circle'

  add_circle: ->
    Circle.create name: prompt "circle name"

  add_friend: ->

module.exports = Main
