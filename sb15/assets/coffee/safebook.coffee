#= require jquery
#= require controller/signin
#= require controller/signup

$ ->
  new Signin(el: $('#signin'))
  new Signup(el: $('#signup'))
