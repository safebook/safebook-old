#= require jquery

#= require model/contact
#= require model/user
#= require model/key
#= require model/msg

#= require view/contact

class window.Contacts extends Spine.Controller

  constructor: ->
    super

    @user = User.first()
    @log "I'm "
    @log @user

    Contact.on 'refresh', (contacts) =>
      contact = contacts[0]
      contact.get_shared(@user.seckey)
      key = new Key(user_id: @user.id, dest_id: contact.id)
      key.share_to(contact).save()

    @render()
    Key.on 'refresh', (key) => @render()

  render: ->
    # fill contacts
    ids = {}
    contacts = []
    msgs = []

    Key.each (key) =>
      # pour l'unicite
      if key.user_id is @user.id
        ids[key.dest_id] = 0
      else
        ids[key.user_id] = 0

    for id of ids
      contacts.push Contact.find(id)

    # fill msgs
    if @selected_contact? and @selected_key?
        Msg.each (msg) =>
          Key.each (k) =>
            if @selected_contact.id is @user.id
              msgs.push msg if k.dest_id == @selected_contact.id and k.user_id == @selected_contact.id and msg.key_tag == k.tag
            else if k.dest_id == @selected_contact.id or k.user_id == @selected_contact.id and msg.key_tag == k.tag
              msgs.push msg

    @html JST['view/contact'](Contact: Contact, Key: Key, contacts: contacts, msgs: msgs)

  events:
    'click #contacts li' : 'select_contact'
    'click #send'   : 'send_message'
    'click #add'    : 'add_contact'

  select_contact: (e) ->
    contact = key = null

    pseudo = $(e.target).text()
    Contact.each (c) ->
      contact = c if c.pseudo is pseudo
    unless contact
      @log "contact not found"
    else
      @selected_contact = contact
      Key.each (k) ->
        key = k if k.dest_id == contact.id or k.user_id == contact.id
      @selected_key = key

    @render()

  send_message: ->
    msg = new Msg(user_id: @user.id, key_tag: @selected_key.tag, value: $("#message").val())
    msg.hide_with(@selected_key).save()
    Msg.addRecord(msg)
    @render()

  add_contact: ->
    Contact.fetch(id: $('#friend').val())
    @render()
