#= require sjcl

window.S =
  cipher: sjcl.cipher.aes
  mode: sjcl.mode.gcm
  curve: sjcl.ecc.curves.c384
  armor: sjcl.codec.base64.fromBits
  unarmor: sjcl.codec.base64.toBits

  encrypt: (key, data, iv) ->
    cipher = new S.cipher(key)
    S.mode.encrypt(cipher, data, iv)

  decrypt: (key, data, iv) ->
    cipher = new S.cipher(key)
    S.mode.decrypt(cipher, data, iv)

  hide: (key, data) -> # (bin, bin) -> b64
    iv = sjcl.random.randomWords(4)
    sjcl.codec.base64.fromBits(sjcl.bitArray.concat(iv, S.encrypt(key, data, iv)))

  bare: (key, data) -> # (bin, b64) -> bin
    data = sjcl.codec.base64.toBits(data)
    iv = sjcl.bitArray.bitSlice(data, 0, 128)
    data = sjcl.bitArray.bitSlice(data, 128)
    S.decrypt(key, data, iv)

  hide_text: (key, text) -> # (bin, utf8) -> b64
    S.hide(key, sjcl.codec.utf8String.toBits(text))

  bare_text: (key, data) -> # (bin, b64) -> utf8
    sjcl.codec.utf8String.fromBits(S.bare(key, data))

  hide_key: (key, data) -> # (bin, bin) -> b64
    S.hide(key, data)

  bare_key: (key, data) -> # (bin, b64) -> bin
    S.bare(key, data)

  hide_seckey: (key, seckey) -> # (bin, sec) -> b64
    S.hide(key, seckey.toBits())

  bare_seckey: (key, data) -> # (bin, b64) -> sec
    sjcl.bn.fromBits S.bare(key, data)

  auth: (pseudo, password) ->
    pseudo = sjcl.codec.utf8String.toBits(pseudo)
    password = sjcl.codec.utf8String.toBits(password)

    pbkdf2 = sjcl.misc.pbkdf2(pseudo, password)
    cipher = new S.cipher(pbkdf2)

    x00 = sjcl.codec.hex.toBits '0x00000000000000000000000000000000'
    x01 = sjcl.codec.hex.toBits '0x00000000000000000000000000000000'

    user_key: cipher.encrypt(x00), token: S.armor(cipher.encrypt(x01))

  signup: (user_key) ->
    seckey = sjcl.bn.random(this.curve.r, 6)
    pubkey = sjcl.codec.base64.fromBits(this.curve.G.mult(seckey).toBits())
    seckey: seckey, pubkey: pubkey, data: S.hide_seckey(user_key, seckey)

  tag: ->
    S.armor sjcl.random.randomWords(8)

  new_key: (key) ->
    key_value = sjcl.random.randomWords(8)
    value: key_value, data: S.hide_key(key, key_value)

  get_shared: (seckey, pubkey) ->
    console.log "in get shared"
    console.log pubkey
    console.log seckey
    point = S.curve.fromBits(sjcl.codec.base64.toBits(pubkey))
    console.log "points"
    console.log point
    console.log point.mult seckey
    sjcl.hash.sha256.hash point.mult(seckey).toBits()

#module?.exports = S
