Backbone.emulateJSON = true
$ ->
  Account = new User

  class View extends Backbone.View
    el: $("#content")

    events:
      'focus input'     : 'clean_input',
      'blur #pseudo'    : 'check_pseudo',
      'blur #email'     : 'check_email',
      'blur #password'  : 'check_password',
      'blur #confirm'   : 'check_confirm',
      'click #eat'      : 'click_file'
      "change #input_file" : 'use_file'
      'click .next'     : 'signup'

    clean_input: (e) ->
      $(e.target).removeClass "invalid"

    check_pseudo: ->
      #if @last_pseudo_checked isnt $("#pseudo").val()
      # @last_pseudo_checked = $("pseudo").val()
      User.if_exist $("#pseudo").val(), ->
        $("#pseudo").addClass "invalid"

    check_email: ->
      unless /^[0-9A-Za-z._%+-]+@[0-9A-Za-z.-]+\.[A-Za-z]{2,6}$/.test $("#email").val()
        $("#email").addClass "invalid"

    check_password: ->
      pw = $("#password").val()
      unless /[0-9]+/.test(pw) && /[a-z]+/.test(pw) and /[A-Z]+/.test(pw) and pw.length >= 8
        $("#password").addClass "invalid"

    check_confirm: ->
      if $("#password").val() isnt $("#confirm").val()
        $("#confirm").addClass "invalid"

    click_file: ->
      $("#input_file").click()
      false

    use_file: (e) ->
      file = e.target.files[0]
      console.log(file.name)
      console.log(file.size)
      hash_file file, (hash) ->
        console.log sjcl.codec.hex.fromBits(hash)
        entropy.add hash, 256, "hash"

    signup: ->
      pseudo = $("#pseudo").val()
      password = $("#password").val()
      email = $("#email").val()

      Account.set pseudo: pseudo, email: email
      Account.set Safebook.log(pseudo, password)
      Account.set Safebook.gen(Account.get("secret"))

      Account.on "sync", =>
        alert "Bravo :)"
      Account.on "error", (model, xhr) =>
        errors = JSON.parse(xhr.responseText)
        if errors.pseudo
          console.log "pseudo"
        else if errors.email
          console.log "email"
      Account.save()
  new View
###
      Account.on "sync", =>
        Account.off()

        @undelegateEvents()
        new Two

      Account.on "error", (s, xhr) =>
        Account.off()

        res = JSON.parse xhr.response
        if res.errors.pseudo
          $("#pseudo").addClass "invalid"
        if res.errors.email
          $("#email").addClass "invalid"

        message = ""
        for key of res.errors
          message += key
          message += " "+msg for msg in res.errors[key]
          message += ". "
        $("#notify").text message

      Account.save()
###
