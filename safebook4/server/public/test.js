var App, curve, from_b64, from_hex, from_utf8, to_b64, to_hex, to_utf8;

curve = sjcl.ecc.curves.c384;

App = {
  C: {},
  M: {}
};

to_b64 = sjcl.codec.base64.fromBits;

from_b64 = sjcl.codec.base64.toBits;

to_hex = sjcl.codec.hex.fromBits;

from_hex = sjcl.codec.hex.toBits;

to_utf8 = sjcl.codec.utf8String.fromBits;

from_utf8 = sjcl.codec.utf8String.toBits;

App.S = {
  cipher: sjcl.cipher.aes,
  mode: sjcl.mode.ccm,
  curve: sjcl.ecc.curves.c384,
  encrypt: function(key, data, iv) {
    var cipher;
    cipher = new App.S.cipher(key);
    return App.S.mode.encrypt(cipher, data, iv);
  },
  decrypt: function(key, data, iv) {
    var cipher;
    cipher = new App.S.cipher(key);
    return App.S.mode.decrypt(cipher, data, iv);
  },
  hide: function(key, data) {
    var iv;
    iv = sjcl.random.randomWords(4);
    return to_b64(sjcl.bitArray.concat(iv, App.S.encrypt(key, data, iv)));
  },
  bare: function(key, data) {
    var hidden_data, iv;
    data = from_b64(data);
    iv = sjcl.bitArray.bitSlice(data, 0, 128);
    hidden_data = sjcl.bitArray.bitSlice(data, 128);
    return App.S.decrypt(key, hidden_data, iv);
  },
  hide_text: function(key, text) {
    return App.S.hide(key, from_utf8(text));
  },
  bare_text: function(key, data) {
    return to_utf8(App.S.bare(key, data));
  },
  hide_seckey: function(key, seckey) {
    return App.S.hide(key, seckey.toBits());
  },
  bare_seckey: function(key, data) {
    return sjcl.bn.fromBits(App.S.bare(key, data));
  }
};

var _Groups,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.M.Group = (function(_super) {
  __extends(Group, _super);

  function Group() {
    return Group.__super__.constructor.apply(this, arguments);
  }

  Group.prototype.urlRoot = '/groups';

  Group.prototype.toJSON = function() {
    return _.pick(this.attributes, "id", "user_id", "name", "hidden_data");
  };

  Group.prototype.generate = function(user) {
    var cipher, data, iv;
    cipher = new sjcl.cipher.aes(user.get('shared'));
    iv = sjcl.random.randomWords(4);
    data = sjcl.random.randomWords(8);
    this.set({
      user_id: user.get('pseudo'),
      data: data,
      hidden_data: sjcl.codec.base64.fromBits(sjcl.bitArray.concat(iv, sjcl.mode.ccm.encrypt(cipher, data, iv)))
    });
    return this;
  };

  return Group;

})(Backbone.Model);

_Groups = (function(_super) {
  __extends(_Groups, _super);

  function _Groups() {
    return _Groups.__super__.constructor.apply(this, arguments);
  }

  _Groups.prototype.model = App.M.Group;

  return _Groups;

})(Backbone.Collection);

App.M.Groups = new _Groups();

var _Keys,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.M.Key = (function(_super) {
  __extends(Key, _super);

  Key.prototype.urlRoot = '/keys';

  Key.prototype.toJSON = function() {
    this.set_id_from_users();
    return this.pick("id", "user_id", "dest_id", "hidden_data");
  };

  function Key() {
    this.log = __bind(this.log, this);
    Key.__super__.constructor.apply(this, arguments);
    this.get_users_from_id();
    console.log("key state");
    console.log(this.attributes);
    if (this.has('hidden_data') && !this.has('tag')) {
      this.compute_tag();
    }
    if (this.has('hidden_data') && !this.has('data')) {
      this.bare();
    }
  }

  Key.prototype.get_users_from_id = function() {
    if (this.has('user_id')) {
      this.set({
        user: App.M.Users.findWhere({
          id: this.get('user_id')
        })
      });
    }
    if (this.has('dest_id')) {
      return this.set({
        dest: App.M.Users.findWhere({
          id: this.get('dest_id')
        })
      });
    }
  };

  Key.prototype.set_id_from_users = function() {
    if (!this.has('user_id')) {
      this.set({
        user_id: this.get('user').get('id')
      });
    }
    if (!this.has('dest_id')) {
      return this.set({
        dest_id: this.get('dest').get('id')
      });
    }
  };

  Key.prototype.get_shared = function() {
    if (this.get('dest').get('id') !== App.User.get('id')) {
      return this.get('dest').get('shared');
    } else {
      return this.get('user').get('shared');
    }
  };

  Key.prototype.generate = function(user) {
    var hidden_data;
    this.set({
      data: sjcl.random.randomWords(8),
      user_id: this.get('user_id'),
      dest_id: this.get('dest_id')
    });
    console.log('data:' + to_b64(this.get('data')));
    console.log('key:' + to_b64(this.get_shared()));
    hidden_data = App.S.hide(this.get_shared(), this.get('data'));
    this.set({
      hidden_data: hidden_data
    });
    console.log('hidden:' + this.get('hidden_data'));
    return this.compute_tag();
  };

  Key.prototype.compute_tag = function() {
    this.set({
      tag: to_hex(sjcl.bitArray.bitSlice(from_b64(this.get('hidden_data')), 0, 32))
    });
    return this;
  };

  Key.prototype.bare = function() {
    console.log('hidden:' + this.get('hidden_data'));
    console.log('key:' + to_b64(this.get_shared()));
    this.set({
      data: App.S.bare(this.get_shared(), this.get('hidden_data'))
    });
    console.log('data:' + to_b64(this.get('data')));
    return this.log();
  };

  Key.prototype.log = function() {
    var b64;
    b64 = function(v) {
      if (v) {
        return to_b64(v);
      } else {
        return v;
      }
    };
    console.log("KEY (" + (this.get('tag')) + ") ::\nuser(" + (this.get('user').get('id')) + ") w/ (" + (b64(this.get('user').get('shared'))) + ")\ndest(" + (this.get('dest').get('id')) + ") w/ (" + (b64(this.get('dest').get('shared'))) + ")\nhidden_data(" + (this.get('hidden_data')) + ")\ndata(" + (b64(this.get('data'))) + ")");
    return this;
  };

  return Key;

})(Backbone.Model);

_Keys = (function(_super) {
  __extends(_Keys, _super);

  function _Keys() {
    return _Keys.__super__.constructor.apply(this, arguments);
  }

  _Keys.prototype.model = App.M.Key;

  _Keys.prototype.from = function(user_id) {
    return this.where({
      user_id: user_id
    });
  };

  _Keys.prototype.to = function(dest_id) {
    return this.where({
      dest_id: dest_id
    });
  };

  return _Keys;

})(Backbone.Collection);

App.M.Keys = new _Keys();

var _Messages,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.M.Message = (function(_super) {
  __extends(Message, _super);

  Message.prototype.urlRoot = '/messages';

  Message.prototype.toJSON = function() {
    if (!this.has('user_id')) {
      this.set({
        user_id: this.get('user').get('id')
      });
    }
    if (!this.has('key_id')) {
      this.set({
        key_id: this.get('key').get('id')
      });
    }
    return _.pick(this.attributes, "id", "user_id", "key_id", "hidden_data");
  };

  function Message() {
    this.bare = __bind(this.bare, this);
    this.hide = __bind(this.hide, this);
    Message.__super__.constructor.apply(this, arguments);
    if (this.has('user_id')) {
      this.set({
        user: App.M.Users.findWhere({
          id: this.get('user_id')
        })
      });
    }
    if (this.has('key_id')) {
      this.set({
        key: App.M.Keys.findWhere({
          id: this.get('key_id')
        })
      });
    }
    if (this.has('hidden_data') && !this.has('data')) {
      this.bare();
    }
  }

  Message.prototype.hide = function() {
    return this.set({
      hidden_data: App.S.hide_text(this.get('key').get("data"), this.get('data'))
    });
  };

  Message.prototype.bare = function() {
    return this.set({
      data: App.S.bare_text(this.get('key').get("data"), this.get('hidden_data'))
    });
  };

  return Message;

})(Backbone.Model);

_Messages = (function(_super) {
  __extends(_Messages, _super);

  function _Messages() {
    return _Messages.__super__.constructor.apply(this, arguments);
  }

  _Messages.prototype.model = App.M.Message;

  return _Messages;

})(Backbone.Collection);

App.M.Messages = new _Messages();

var _Passwords,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.M.Password = (function(_super) {
  __extends(Password, _super);

  function Password() {
    return Password.__super__.constructor.apply(this, arguments);
  }

  Password.prototype.urlRoot = '/keys';

  Password.prototype.toJSON = function() {
    return _.pick(this.attributes, "id", "hidden_url", "hidden_password");
  };

  Password.prototype.generate = function() {
    return this.set({
      password: to_utf8(sjcl.random.randomWords(3))
    });
  };

  Password.prototype.hide = function() {
    var cipher, iv;
    cipher = new sjcl.cipher.aes(App.User.get('mainkey'));
    iv = sjcl.random.randomWords(4);
    this.set({
      hidden_url: to_b64(sjcl.bitArray.concat(iv, sjcl.mode.ccm.encrypt(cipher, from_utf8(this.get('url')), iv)))
    });
    iv = sjcl.random.randomWords(4);
    return this.set({
      hidden_password: to_b64(sjcl.bitArray.concat(iv, sjcl.mode.ccm.encrypt(cipher, from_utf8(this.get('password')), iv)))
    });
  };

  Password.prototype.bare = function() {
    var cipher, hidden_password, hidden_url, iv;
    cipher = new sjcl.cipher.aes(App.User.get('mainkey'));
    iv = sjcl.bitArray.bitSlice(sjcl.codec.base64.toBits(this.get('hidden_password')), 0, 128);
    hidden_password = sjcl.bitArray.bitSlice(sjcl.codec.base64.toBits(this.get('hidden_password')), 128);
    this.set({
      password: to_utf8(sjcl.mode.ccm.decrypt(cipher, hidden_password, iv))
    });
    iv = sjcl.bitArray.bitSlice(sjcl.codec.base64.toBits(this.get('hidden_url')), 0, 128);
    hidden_url = sjcl.bitArray.bitSlice(sjcl.codec.base64.toBits(this.get('hidden_url')), 128);
    return this.set({
      url: to_utf8(sjcl.mode.ccm.decrypt(cipher, hidden_url, iv))
    });
  };

  return Password;

})(Backbone.Model);

_Passwords = (function(_super) {
  __extends(_Passwords, _super);

  function _Passwords() {
    return _Passwords.__super__.constructor.apply(this, arguments);
  }

  _Passwords.prototype.model = App.M.Password;

  return _Passwords;

})(Backbone.Collection);

App.M.Passwords = new _Passwords();

var _Users,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.M.User = (function(_super) {
  __extends(User, _super);

  User.prototype.urlRoot = '/users';

  User.prototype.idAttribute = 'pseudo';

  User.prototype.toJSON = function() {
    return this.pick("id", "pseudo", "pubkey", "remote_secret", "hidden_seckey", "hidden_mainkey");
  };

  function User() {
    this.log = __bind(this.log, this);
    this.load = __bind(this.load, this);
    User.__super__.constructor.apply(this, arguments);
    if (!this.isNew()) {
      this.load();
    } else {
      this.on('sync', this.load);
    }
    this;
  }

  User.prototype.load = function() {
    if (!this.has('seckey') && this.has('hidden_seckey')) {
      this.bare_ecdh();
    }
    if (!this.has('mainkey') && this.has('hidden_mainkey')) {
      this.bare_mainkey();
    }
    if (!this.has('shared') && this.has('pubkey')) {
      return this.shared();
    }
  };

  User.prototype.log = function() {
    var shared;
    shared = this.has('shared') ? to_b64(this.get('shared')) : "(null)";
    return console.log("USER (" + (this.get('pseudo')) + ") -->\npubkey(" + (this.get('pubkey')) + ")\nshared(" + shared + ")");
  };

  User.prototype.auth = function() {
    var cipher, key, x00, x01, x02, x03;
    x00 = sjcl.codec.hex.toBits("0x00000000000000000000000000000000");
    x01 = sjcl.codec.hex.toBits("0x00000000000000000000000000000001");
    x02 = sjcl.codec.hex.toBits("0x00000000000000000000000000000002");
    x03 = sjcl.codec.hex.toBits("0x00000000000000000000000000000003");
    key = sjcl.misc.pbkdf2(this.get('password'), this.get('pseudo'));
    cipher = new sjcl.cipher.aes(key);
    this.set('local_secret', sjcl.bitArray.concat(cipher.encrypt(x00), cipher.encrypt(x01)));
    return this.set('remote_secret', to_b64(sjcl.bitArray.concat(cipher.encrypt(x02), cipher.encrypt(x03))));
  };

  User.prototype.create_ecdh = function() {
    this.set({
      seckey: sjcl.bn.random(curve.r, 6)
    });
    return this.set({
      pubkey: to_b64(curve.G.mult(this.get('seckey')).toBits())
    });
  };

  User.prototype.hide_ecdh = function() {
    return this.set({
      hidden_seckey: App.S.hide_seckey(this.get('local_secret'), this.get('seckey'))
    });
  };

  User.prototype.bare_ecdh = function() {
    return this.set({
      seckey: App.S.bare_seckey(this.get('local_secret'), this.get('hidden_seckey'))
    });
  };

  User.prototype.create_mainkey = function() {
    return this.set({
      mainkey: sjcl.random.randomWords(8)
    });
  };

  User.prototype.hide_mainkey = function() {
    return this.set({
      hidden_mainkey: App.S.hide(this.get('local_secret'), this.get('mainkey'))
    });
  };

  User.prototype.bare_mainkey = function() {
    return this.set({
      mainkey: App.S.bare(this.get('local_secret'), this.get('hidden_mainkey'))
    });
  };

  User.prototype.shared = function(user) {
    var point;
    point = curve.fromBits(from_b64(this.get('pubkey'))).mult(App.User.get('seckey'));
    return this.set({
      shared: sjcl.hash.sha256.hash(point.toBits())
    });
  };

  User.prototype.keys = function() {
    var keys;
    keys = _.extend(App.M.Keys.where({
      user_id: this.get('id')
    }), App.M.Keys.where({
      dest_id: this.get('id')
    }));
    return keys;
  };

  return User;

})(Backbone.Model);

_Users = (function(_super) {
  __extends(_Users, _super);

  function _Users() {
    return _Users.__super__.constructor.apply(this, arguments);
  }

  _Users.prototype.model = App.M.User;

  return _Users;

})(Backbone.Collection);

App.M.Users = new _Users();

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.C.Auth = (function(_super) {
  __extends(Auth, _super);

  function Auth() {
    Auth.__super__.constructor.apply(this, arguments);
  }

  Auth.prototype.events = {
    'click #signup_btn': 'signup',
    'click #signin_btn': 'signin',
    'click #test_btn': 'test'
  };

  Auth.prototype.signup = function() {
    App.User.set({
      pseudo: this.$('#pseudo_input').val(),
      password: this.$('#password_input').val()
    });
    App.User.auth().create_ecdh().create_mainkey().hide_ecdh().hide_mainkey().shared();
    App.User.isNew = function() {
      return true;
    };
    App.User.save();
    return false;
  };

  Auth.prototype.signin = function() {
    App.User.set({
      pseudo: this.$('#pseudo_input').val(),
      password: this.$('#password_input').val()
    });
    App.User.auth();
    App.User.isNew = function() {
      return false;
    };
    App.User.save();
    return false;
  };

  Auth.prototype.test = function() {
    var i, pseudo, _i;
    pseudo = "";
    for (i = _i = 0; _i <= 4; i = ++_i) {
      pseudo += Math.round(Math.random() * 16).toString(16);
    }
    this.$('#pseudo_input').val(pseudo);
    return this.signup();
  };

  return Auth;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.C.Home = (function(_super) {
  __extends(Home, _super);

  function Home() {
    this.render = __bind(this.render, this);
    Home.__super__.constructor.apply(this, arguments);
    this.template = _.template($('#home_tpl').html());
    this.render();
    App.Home = this;
    this.on('refresh', this.render);
    this;
  }

  Home.prototype.render = function() {
    this.$el.html(this.template());
    (new App.C.Users({
      el: $('#users')
    })).render();
    (new App.C.Keys({
      el: $('#keys')
    })).render();
    return (new App.C.Messages({
      el: $('#messages')
    })).render();
  };

  return Home;

})(Backbone.View);


/*
  add_group: ->
    group = new App.M.Group(
      name: $('#group_input').val()
    )
    App.User.shared(App.User) unless App.User.has 'shared' #remove when mainkey is set
    group.generate(App.User).on 'sync', =>
      App.M.Groups.add(group)
      @render()
    group.save()
 */

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.C.Key = (function(_super) {
  __extends(Key, _super);

  function Key() {
    this.delete_key = __bind(this.delete_key, this);
    this.render = __bind(this.render, this);
    Key.__super__.constructor.apply(this, arguments);
    this.template = _.template($('#key_tpl').html());
  }

  Key.prototype.render = function() {
    this.el = $(this.template(this.model.attributes));
    return this;
  };

  Key.prototype.events = {
    'click .key': 'delete_key'
  };

  Key.prototype.delete_key = function() {};

  return Key;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.C.Keys = (function(_super) {
  __extends(Keys, _super);

  function Keys() {
    this.add = __bind(this.add, this);
    this.render = __bind(this.render, this);
    Keys.__super__.constructor.apply(this, arguments);
    this.template = _.template($('#keys_tpl').html());
    this.render();
    App.M.Keys.on('add', this.add);
    this;
  }

  Keys.prototype.render = function() {
    this.$el.html(this.template());
    this.$("ul").empty();
    App.M.Keys.each(this.add);
    return this;
  };

  Keys.prototype.add = function(model) {
    var el, view;
    view = new App.C.Key({
      model: model
    });
    el = view.render().el;
    return this.$("ul").append($(el));
  };

  return Keys;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.C.Message = (function(_super) {
  __extends(Message, _super);

  function Message() {
    this.render = __bind(this.render, this);
    Message.__super__.constructor.apply(this, arguments);
    this.template = _.template($('#message_tpl').html());
  }

  Message.prototype.render = function() {
    this.$el = this.el = $(this.template(this.model.attributes));
    this.delegateEvents();
    return this;
  };

  return Message;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.C.Messages = (function(_super) {
  __extends(Messages, _super);

  function Messages() {
    this.add = __bind(this.add, this);
    this.render = __bind(this.render, this);
    Messages.__super__.constructor.apply(this, arguments);
    this.template = _.template($('#messages_tpl').html());
    App.M.Messages.on('remove', this.render);
    App.M.Messages.on('add', this.add);
  }

  Messages.prototype.render = function() {
    this.$el.html(this.template());
    App.M.Messages.each(this.add);
    return this;
  };

  Messages.prototype.add = function(message) {
    var view;
    view = new App.C.Message({
      model: message
    });
    return this.$("ul").append(view.render().el);
  };

  Messages.prototype.events = {
    'click    #message_btn': 'add_message'
  };

  Messages.prototype.add_message = function() {
    var key, message;
    key = App.Dest.keys()[0];
    message = new App.M.Message({
      data: $('#message_input').val(),
      user: App.User,
      key: key
    });
    message.hide().on('sync', (function(_this) {
      return function() {
        return App.M.Messages.add(message);
      };
    })(this));
    return message.save();
  };

  return Messages;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.C.User = (function(_super) {
  __extends(User, _super);

  function User() {
    this.select_user = __bind(this.select_user, this);
    this.del_user = __bind(this.del_user, this);
    this.render = __bind(this.render, this);
    User.__super__.constructor.apply(this, arguments);
    this.template = _.template($('#user_tpl').html());
    this;
  }

  User.prototype.render = function() {
    this.$el = this.el = $(this.template(this.model.attributes));
    this.delegateEvents();
    return this;
  };

  User.prototype.events = {
    'click .name': 'select_user',
    'click .send': 'send_key',
    'click .del': 'del_user'
  };

  User.prototype.send_key = function() {
    var key;
    key = new App.M.Key({
      user: App.User,
      dest: this.model
    });
    key.generate().on('sync', (function(_this) {
      return function() {
        return App.M.Keys.push(key);
      };
    })(this));
    key.save();
    return false;
  };

  User.prototype.del_user = function() {
    App.M.Users.remove(this.model);
    return false;
  };

  User.prototype.select_user = function() {
    App.Dest = this.model;
    App.Home.trigger('refresh');
    return false;
  };

  return User;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.C.Users = (function(_super) {
  __extends(Users, _super);

  function Users() {
    this.adding_user = __bind(this.adding_user, this);
    this.add_child = __bind(this.add_child, this);
    this.render = __bind(this.render, this);
    Users.__super__.constructor.apply(this, arguments);
    this.template = _.template($('#users_tpl').html());
    App.M.Users.on('remove', this.render);
    App.M.Users.on('add', this.add_child);
    this;
  }

  Users.prototype.render = function() {
    this.$el.html(this.template());
    App.M.Users.each(this.add_child);
    return this;
  };

  Users.prototype.add_child = function(user) {
    var view;
    view = new App.C.User({
      model: user
    });
    return this.$("ul").append(view.render().el);
  };

  Users.prototype.events = {
    'click    #user_btn': 'fetch_user',
    'keypress #user_input': 'adding_user'
  };

  Users.prototype.adding_user = function(e) {
    console.log("keypress");
    if (e.keyCode === 13) {
      return this.fetch_user();
    }
  };

  Users.prototype.fetch_user = function() {
    var pseudo, user;
    console.log("fetching...");
    pseudo = $("#user_input").val();
    user = new App.M.User({
      pseudo: pseudo
    });
    user.on('sync', (function(_this) {
      return function(user) {
        user.shared();
        App.M.Users.add(user.attributes);
        App.Dest = user;
        return App.Home.trigger('refresh');
      };
    })(this));
    return user.fetch();
  };

  return Users;

})(Backbone.View);

var logins;

logins = function() {
  return {
    pseudo: 'test_' + Math.floor(Math.random() * 10000000).toString(),
    password: Math.floor(Math.random() * 100000000000).toString()
  };
};

describe("A user basics", function() {
  beforeEach(function() {
    App.User = new App.Model.User();
    App.Dest = new App.Model.User();
    App.Collection.Users = new _Users();
    App.Collection.Keys = new _Users();
    return App.Collection.Messages = new _Users();
  });
  it("auth", function() {
    return App.User.set(logins()).auth();
  });
  it("create and hide and bare keys", function() {
    return App.User.set(logins()).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey();
  });
  return it("is saved then fetched", function(done) {
    var login;
    login = logins();
    App.User.set(login).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey();
    App.User.isNew = function() {
      return true;
    };
    App.User.on('sync', function() {
      var user;
      user = new App.Model.User();
      user.set(login).auth();
      user.isNew = function() {
        return false;
      };
      user.on('sync', function() {
        return done();
      });
      return user.save();
    });
    return App.User.save();
  });
});

var logins;

logins = function() {
  return {
    pseudo: 'test_' + Math.floor(Math.random() * 10000000).toString(),
    password: Math.floor(Math.random() * 100000000000).toString()
  };
};

describe("Password manager", function() {
  beforeEach(function() {
    App.User = new App.Model.User();
    App.Dest = new App.Model.User();
    App.Collection.Users = new _Users();
    App.Collection.Keys = new _Keys();
    App.Collection.Messages = new _Messages();
    return App.Collection.Passwords = new _Passwords();
  });
  return it("can hide and bare", function() {
    var password;
    App.User.set(logins()).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey();
    password = new App.Model.Password();
    password.set({
      url: "facebook.com"
    });
    password.set({
      password: "meegere"
    });
    return password.hide().bare();
  });
});

var logins;

logins = function() {
  return {
    pseudo: 'test_' + Math.floor(Math.random() * 10000000).toString(),
    password: Math.floor(Math.random() * 100000000000).toString()
  };
};

describe("A crypto user", function() {
  var key_data, login, login2;
  beforeEach(function() {
    App.User = new App.Model.User();
    App.Dest = new App.Model.User();
    App.Collection.Users = new _Users();
    App.Collection.Keys = new _Keys();
    return App.Collection.Messages = new _Messages();
  });
  it("create a shared secret with someone else", function() {
    App.User.create_ecdh();
    App.Dest.create_ecdh();
    App.User.shared(App.Dest);
    App.Dest.shared(App.User);
    return expect(App.User.get('shared')).toEqual(App.Dest.get('shared'));
  });
  key_data = 0;
  login = logins();
  login2 = logins();
  it("send a key to someone else", function(done) {
    var user;
    App.User.set(login).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey();
    App.User.isNew = function() {
      return true;
    };
    user = new App.Model.User();
    user.set(login2).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey();
    user.isNew = function() {
      return true;
    };
    App.User.shared(user);
    user.shared(App.User);
    App.User.on('sync', function() {
      user.on('sync', function() {
        var key;
        key = new App.Model.Key();
        key.generate(user).on('sync', done);
        key_data = key.get('data');
        return key.save();
      });
      return user.save();
    });
    return App.User.save();
  });
  return it("get his keys back", function(done) {
    var user;
    App.User.set(login).auth();
    App.User.isNew = function() {
      return false;
    };
    user = new App.Model.User();
    user.set(login2).auth();
    user.isNew = function() {
      return false;
    };
    App.User.on('sync', function() {
      user.on('sync', function() {
        var key;
        App.User.shared(user);
        user.shared(App.User);
        key = App.Collection.Keys.first().bare(user);
        expect(key.get('data')).toEqual(key_data);
        return done();
      });
      return user.save();
    });
    return App.User.save();
  });
});

var logins;

logins = function() {
  return {
    pseudo: 'test_' + Math.floor(Math.random() * 10000000).toString(),
    password: Math.floor(Math.random() * 100000000000).toString()
  };
};

describe("A social user", function() {
  var login3, login4;
  beforeEach(function() {
    App.User = new App.Model.User();
    App.Dest = new App.Model.User();
    App.Collection.Users = new _Users();
    App.Collection.Keys = new _Keys();
    return App.Collection.Messages = new _Messages();
  });
  login3 = logins();
  login4 = logins();
  it("can send a message on a key he control", function(done) {
    var user;
    App.User.set(login3).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey();
    App.User.isNew = function() {
      return true;
    };
    user = new App.Model.User();
    user.set(login4).auth().create_ecdh().hide_ecdh().create_mainkey().hide_mainkey();
    user.isNew = function() {
      return true;
    };
    App.User.shared(user);
    user.shared(App.User);
    App.User.on('sync', function() {
      user.on('sync', function() {
        var key;
        key = new App.Model.Key();
        key.generate(user).on('sync', function() {
          var message;
          message = new App.Model.Message({
            data: "my message data"
          });
          message.hide(key).on('sync', done);
          return message.save();
        });
        return key.save();
      });
      return user.save();
    });
    return App.User.save();
  });
  return it("get his messages back", function(done) {
    var user;
    App.User.set(login3).auth();
    App.User.isNew = function() {
      return false;
    };
    user = new App.Model.User();
    user.set(login4).auth();
    user.isNew = function() {
      return false;
    };
    App.User.on('sync', function() {
      user.on('sync', function() {
        var key, message;
        App.User.shared(user);
        user.shared(App.User);
        key = App.Collection.Keys.first().bare(user);
        message = App.Collection.Messages.first().bare(key);
        expect(message.get('data')).toEqual("my message data");
        return done();
      });
      return user.save();
    });
    return App.User.save();
  });
});
