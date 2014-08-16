sjcl = require('lib/sjcl')

S =
  cipher: sjcl.cipher.aes
  mode: sjcl.mode.gcm #compile GCM
  curve: sjcl.ecc.curves.c384
  armor: sjcl.codec.base64.fromBits
  unarmor: sjcl.codec.base64.toBits

  encrypt: (key, data, iv) ->
    cipher = new S.cipher(key)
    S.mode.encrypt(cipher, data, iv)

  decrypt: (key, data, iv) ->
    cipher = new S.cipher(key)
    S.mode.decrypt(cipher, data, iv)

  hide: (key, data) ->
    iv = sjcl.random.randomWords(4)
    sjcl.bitArray.concat(iv, S.encrypt(key, data, iv))

  bare: (key, data) ->
    iv = sjcl.bitArray.bitSlice(data, 0, 128)
    data = sjcl.bitArray.bitSlice(data, 128)
    S.decrypt(key, data, iv)

  hide_text: (key, text) ->
    S.hide(key, sjcl.codec.utf8String.toBits(text))

  bare_text: (key, data) ->
    S.bare(key, sjcl.codec.utf8String.toBits(text))

  hide_key: (key, data) ->
    S.hide(key, data)

  bare_key: (key, data) ->
    S.bare(key, data)

  hide_seckey: (key, seckey) ->
    S.hide(key, seckey.toBits())

  bare_seckey: (key, data) ->
    sjcl.bn.fromBits S.bare(key, data)

  key: -> sjcl.random.randomWords(8)

  ec_create: ->
    seckey = sjcl.bn.random(this.curve.r, 6)
    pubkey = sjcl.codec.base64.fromBits(this.curve.G.mult(seckey).toBits())
    seckey: seckey, pubkey: pubkey

  ec_shared: (seckey, pubkey) ->
    point = S.curve.fromBits(sjcl.codec.base64.toBits(pubkey))
    sjcl.hash.sha256.hash point.mult(seckey)

# for Safebook
  login: (pseudo, password) ->
    pseudo = sjcl.codec.utf8String.toBits(pseudo)
    password = sjcl.codec.utf8String.toBits(password)

    pbkdf2 = sjcl.misc.pbkdf2(pseudo, password)
    cipher = new S.cipher(pbkdf2)

    x00 = sjcl.codec.hex.toBits '0x00000000000000000000000000000000'
    x01 = sjcl.codec.hex.toBits '0x00000000000000000000000000000000'

    datakey: cipher.encrypt(x00), token: S.armor(cipher.encrypt(x01))

module?.exports = S
