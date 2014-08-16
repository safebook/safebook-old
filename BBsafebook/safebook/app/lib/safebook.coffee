sjcl = require("lib/sjcl")

S =
  sjcl: sjcl

  cipher: sjcl.cipher.aes
  mode: sjcl.mode.ccm
  curve: sjcl.ecc.curves.c384
  # puis-je utiliser @ ?

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
    sjcl.bn.fromBits S.bare(key, date)


  ecdh_secret: ->
    seckey = sjcl.bn.random(this.curve.r, 6)
    pubkey = sjcl.codec.base64.fromBits(this.curve.G.mult(seckey).toBits())
    seckey: seckey, pubkey: pubkey

  ecdh_shared: (seckey, pubkey) ->
    point = S.curve.fromBits(sjcl.codec.base64.toBits(pubkey))
    sjcl.hash.sha256.hash point.mult(seckey)

if module?.exports?
  module.exports = S
