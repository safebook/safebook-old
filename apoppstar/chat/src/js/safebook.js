var Safebook = {
  mode:  sjcl.mode.gcm, // CCM for safety?
  curve: sjcl.ecc.curves.c384, // Check si c'est pas la même que cryptocat

  log: function(pseudo, password) {
    var result = sjcl.misc.pbkdf2(from_s(password), from_s(pseudo)),
        cipher = new sjcl.cipher.aes(result);
    
    return {
      secret: cipher.encrypt(from_h('0x00000000000000000000000000000000')),
      token: to_b64(cipher.encrypt(from_h('0x00000000000000000000000000000001')))
    };
  },

  ecdh: function() {
    var seckey = sjcl.bn.random(this.curve.r, 0);/*\ 0 = PARANOIA \*/
    var pubkey = this.curve.G.mult(seckey).toBits();
    return {
      seckey: seckey,
      pubkey: to_b64(pubkey)
    };
  },

  gen: function(secret) {
    var cipher, seckey, pubkey, data;

    seckey  = sjcl.bn.random(this.curve.r, 0);/*\ 0 = PARANOIA \*/
    pubkey  = this.curve.G.mult(seckey).toBits();
    cipher  = new sjcl.cipher.aes(secret);
    iv      = sjcl.random.randomWords(4);
    data    = this.mode.encrypt(cipher, pubkey, iv);

    return {
      seckey: seckey,
      pubkey: to_b64(pubkey),
      data:   to_b64(sjcl.bitArray.concat(iv, data))
    }
  },

  encrypt_key: function(key, data) {
    var iv, cipher, ciphertext;

    iv = sjcl.random.randomWords(4)
    cipher = new sjcl.cipher.aes(key);

    ciphertext = this.mode.encrypt(cipher, data, iv);
    
    return to_b64(sjcl.bitArray.concat(iv, ciphertext));
  },

  decrypt_key: function(key, data) {
    var iv, cipher, ciphertext, data = from_b64(data);

    iv = sjcl.bitArray.bitSlice(data, 0, 128);
    ciphertext = sjcl.bitArray.bitSlice(data, 128);
    cipher = new sjcl.cipher.aes(key);

    return this.mode.decrypt(cipher, ciphertext, iv);
  },
  /*
  gen: function() {
    var main_key, sec_key, pub_key;

    main_key = sjcl.random.randomWords(8);
    sec_key  = sjcl.bn.random(this.curve.r, 0);
    pub_key  = to_b64(this.curve.G.mult(sec_key).toBits());

    return [main_key, sec_key, pub_key];
  },
  */

  // (BitArray) account_key
  // (BitArray) master_key
  // (BigNumber) secret_key
  //
  // Return (Base64) hidden_keyring
  hide_keyring: function(account_key, master_key, secret_key) {
    var data, cipher, iv, ciphertext;

    data = sjcl.bitArray.concat(master_key, secret_key.toBits());

    cipher  = new sjcl.cipher.aes(account_key);
    iv = sjcl.random.randomWords(4);

    ciphertext = this.mode.encrypt(cipher, data, iv);

    return to_b64(sjcl.bitArray.concat(iv, ciphertext));
  },

  // (BitArray) account_key
  // (Base64)   hidden_keyring
  //
  // Return [ (BitArray) master_key , (BigNumber) secret_key ]
  load_keyring: function(account_key, hidden_keyring) {
    var iv, cipher, cdata, result, main, sec;

    ciphertext = from_b64(hidden_keyring);
    iv    = sjcl.bitArray.bitSlice(ciphertext, 0, 128);
    data  = sjcl.bitArray.bitSlice(ciphertext, 128);

    cipher = new sjcl.cipher.aes(account_key);
    plaintext = this.mode.decrypt(cipher, data, iv);

    return [sjcl.bitArray.bitSlice(plaintext, 0, 256),
      sjcl.bn.fromBits(sjcl.bitArray.bitSlice(plaintext, 256))];
  },

  // (BitArray) main_key
  // Return [ (Base64) seed , (BitArray) circle_key , (Base64) tag ]
  gen_circle: function(main_key) {
    var cipher, tag, circle_key;

    tag  = sjcl.random.randomWords(2);

    cipher = new sjcl.cipher.aes(main_key);

    circle_key = sjcl.bitArray.concat(
      cipher.encrypt(sjcl.random.randomWords(4)),
      cipher.encrypt(sjcl.random.randomWords(4))
    );

    return [ circle_key, to_b64(tag) ];
  },

  // (BitArray) circle_key
  // (String) message
  // Return (Base64) hidden_message
  hide_message: function(circle_key, message) {
    var iv, cipher, ciphertext;

    iv = sjcl.random.randomWords(4);
    cipher = new sjcl.cipher.aes(circle_key);
    ciphertext = this.mode.encrypt(cipher, from_s(message), iv);
    
    return to_b64(sjcl.bitArray.concat(iv, ciphertext));
  },

  // (BitArray) circle_key
  // (Base64) hidden_message
  // Return (String) message
  load_message: function(circle_key, hidden_message) {
    var iv, cipher, ciphertext, data = from_b64(hidden_message);

    iv = sjcl.bitArray.bitSlice(data, 0, 128);
    ciphertext = sjcl.bitArray.bitSlice(data, 128);

    cipher = new sjcl.cipher.aes(circle_key);
    return to_s(this.mode.decrypt(cipher, ciphertext, iv));
  },

  // (BigNumber) secret_key
  // (Base64) public_key
  // Return [ (BitArray) shared_key , (Base64) shared_tag ]
  get_shared_key: function(secret_key, public_key) {
    var public_point, shared_point, hash, key, tag;

    public_point = this.curve.fromBits( from_b64(public_key) );
    shared_point = public_point.mult( secret_key );

    hash = sjcl.hash.sha512.hash(shared_point.toBits());

    return sjcl.bitArray.bitSlice(hash, 0, 256);
  },

  // (BitArray) shared_key
  // (BitArray) circle_key
  // Return (Base64) hidden_circle
  hide_circle: function(shared_key, key, tag) {
    var iv, cipher, ciphertext;

    plaintext = sjcl.bitArray.concat(key, from_b64(tag));

    iv = sjcl.random.randomWords(4);
    cipher = new sjcl.cipher.aes(shared_key);
    ciphertext = this.mode.encrypt(cipher, plaintext, iv);
    
    return to_b64(sjcl.bitArray.concat(iv, ciphertext));
  },

  // (BitArray) shared_key
  // (Base64) hidden_circle
  // Return (BitArray) circle_key
  load_circle: function(shared_key, blob) {
    var iv, cipher, ciphertext, result, data = from_b64(blob);

    iv = sjcl.bitArray.bitSlice(data, 0, 128);
    ciphertext = sjcl.bitArray.bitSlice(data, 128);

    cipher = new sjcl.cipher.aes(shared_key);

    result = this.mode.decrypt(cipher, ciphertext, iv);
    return [ sjcl.bitArray.bitSlice(result, 0, 256),
      to_b64(sjcl.bitArray.bitSlice(result, 256)) ];
  },

  // (BitArray) password_key
  // (String) domain_url
  gen_password: function(/*BitArray*/passw_key, /*String*/domain_url) {
    var cipher, bin_url;
    cipher = new sjcl.cipher.aes(key);

    bin_url = sjcl.codec.utf8String.toBits(domain_url);
    bin_url = sjcl.hash.sha256.hash(bin_url);
    bin_url = sjcl.bitArray.bitSlice(bin_url, 0, 128);

    return to_b64( cipher.encrypt(bin_url) );
  },
}

var from_b = sjcl.codec.bytes.toBits;
var to_b = sjcl.codec.bytes.fromBits;

var from_s = sjcl.codec.utf8String.toBits;
var to_s = sjcl.codec.utf8String.fromBits;

var from_b64 = sjcl.codec.sb64.toBits;
var to_b64 = sjcl.codec.sb64.fromBits;

var from_h = sjcl.codec.hex.toBits;
var to_h = sjcl.codec.hex.fromBits;
