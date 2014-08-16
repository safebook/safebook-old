# depreciated
curve     = sjcl.ecc.curves.c384

# ## App Structure

App = {
  C: {}
  M: {}
}

# ## Conversion helpers

to_b64    = sjcl.codec.base64.fromBits
from_b64  = sjcl.codec.base64.toBits

to_hex    = sjcl.codec.hex.fromBits
from_hex  = sjcl.codec.hex.toBits

to_utf8   = sjcl.codec.utf8String.fromBits
from_utf8 = sjcl.codec.utf8String.toBits

# ## Crypto helpers

App.S =
  cipher: sjcl.cipher.aes
  mode: sjcl.mode.ccm
  curve: sjcl.ecc.curves.c384

  encrypt: (key, data, iv) -> # (bin, bin, bin) -> bin
    cipher = new App.S.cipher(key)
    App.S.mode.encrypt(cipher, data, iv)

  decrypt: (key, data, iv) -> # (bin, bin, bin) -> bin
    cipher = new App.S.cipher(key)
    App.S.mode.decrypt(cipher, data, iv)

  hide: (key, data) -> # (bin, bin) -> b64
    iv = sjcl.random.randomWords(4)
    to_b64 sjcl.bitArray.concat(iv, App.S.encrypt(key, data, iv))

  bare: (key, data) -> # (bin, b64) -> bin
    data = from_b64(data)
    iv = sjcl.bitArray.bitSlice(data, 0, 128)
    hidden_data = sjcl.bitArray.bitSlice(data, 128)
    App.S.decrypt(key, hidden_data, iv)

  # ### For keys
  hide_text: (key, text) -> # (bin, utf8) -> b64
    App.S.hide(key, from_utf8(text))

  bare_text: (key, data) -> # (bin, b64) -> utf8
    to_utf8(App.S.bare(key, data))

  # ### For seckeys
  hide_seckey: (key, seckey) -> # (bin, sec) -> b64
    App.S.hide(key, seckey.toBits())

  bare_seckey: (key, data) -> # (bin, b64) -> sec
    sjcl.bn.fromBits App.S.bare(key, data)
