module.exports = (App) ->

  # FIX
  gen_id:   -> Math.floor(Math.random() * 10000000)
  gen_salt: -> "fixthissalt"
  hash:     (password, salt) -> password
