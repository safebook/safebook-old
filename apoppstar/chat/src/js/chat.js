// Generated by CoffeeScript 1.6.3
(function() {
  var Entropy, EntropyClass, Keys, View, hash_file, socket,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  EntropyClass = (function() {
    function EntropyClass() {
      this.entropy = 0;
      this.collect();
    }

    EntropyClass.prototype.collect = function() {
      var array,
        _this = this;
      window.addEventListener("load", (function(e) {
        return _this.time_collector(e);
      }), false);
      window.addEventListener("mousemove", (function(e) {
        return _this.mouse_collector(e);
      }), false);
      window.addEventListener("keypress", (function(e) {
        return _this.keys_collector(e);
      }), false);
      if (window.crypto && window.crypto.getRandomValues) {
        array = new Uint32Array(32);
        window.crypto.getRandomValues(array);
        return this.add(array, 1024, "getRandomValues");
      }
    };

    EntropyClass.prototype.add = function(value, estimate, source) {
      this.entropy += estimate;
      sjcl.random.addEntropy(value, estimate, source);
      if (this.refresh) {
        return this.refresh(this.entropy);
      }
    };

    EntropyClass.prototype.time_collector = function(e) {
      return this.add((new Date()).valueOf(), 2, "loadtime");
    };

    EntropyClass.prototype.mouse_collector = function(e) {
      var x, y;
      x = e.x || e.clientX || e.offsetX || 0;
      y = e.y || e.clientY || e.offsetY || 0;
      return this.add([x, y], 2, "mouse");
    };

    EntropyClass.prototype.keys_collector = function(e) {
      var keyCode, ms;
      ms = new Date().getMilliseconds();
      keyCode = e.keyCode || e.which;
      return this.add([ms, keyCode], 2, "keys");
    };

    return EntropyClass;

  })();

  Entropy = new EntropyClass;

  hash_file = function(file, callback) {
    var BLOCKSIZE, hash_slice, i, j, reader, sha;
    BLOCKSIZE = 2048;
    i = 0;
    j = Math.min(BLOCKSIZE, file.size);
    reader = new FileReader();
    sha = new sjcl.hash.sha256();
    hash_slice = function(i, j) {
      return reader.readAsArrayBuffer(file.slice(i, j));
    };
    reader.onloadend = function(e) {
      var array, bitArray;
      array = new Uint8Array(this.result);
      bitArray = sjcl.codec.bytes.toBits(array);
      sha.update(bitArray);
      if (i !== file.size) {
        i = j;
        j = Math.min(i + BLOCKSIZE, file.size);
        return setTimeout((function() {
          return hash_slice(i, j);
        }), 0);
      } else {
        return callback(sha.finalize());
      }
    };
    return hash_slice(i, j);
  };

  socket = io.connect('http://0.0.0.0:8004');

  Keys = {};

  View = null;

  $(function() {
    var _ref;
    return window.LoadView = (function(_super) {
      __extends(LoadView, _super);

      function LoadView() {
        this.wait_for_chat = __bind(this.wait_for_chat, this);
        this.create_chat = __bind(this.create_chat, this);
        this.start_chat = __bind(this.start_chat, this);
        _ref = LoadView.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      LoadView.prototype.template = _.template($('#loadTemp').html());

      LoadView.prototype.el = $('body');

      LoadView.prototype.initialize = function() {
        var event;
        this.$el.html(this.template());
        for (event in this.socket_events) {
          socket.on(event, this[this.socket_events[event]]);
        }
        return Entropy.refresh = function(value) {
          return $('#randomness').text(value);
        };
      };

      LoadView.prototype.events = {
        'click #hash_file': 'select_file',
        'change #file': 'hash_file',
        'click #start': 'start_chat'
      };

      LoadView.prototype.select_file = function() {
        $('#file').click();
        return false;
      };

      LoadView.prototype.hash_file = function(e) {
        var file,
          _this = this;
        file = e.target.files[0];
        return hash_file(file, function(hash) {
          console.log(sjcl.codec.hex.fromBits(hash));
          return Entropy.add(hash, 256, "hash");
        });
      };

      LoadView.prototype.start_chat = function() {
        Keys = Safebook.ecdh();
        this.pseudo = $("#pseudo").val();
        this.room = document.location.pathname.slice(1);
        if (this.room === '') {
          socket.emit('register', {
            pseudo: this.pseudo,
            pubkey: Keys.pubkey
          });
        } else {
          socket.emit('ask', {
            room: this.room,
            pseudo: this.pseudo,
            pubkey: Keys.pubkey
          });
        }
        return false;
      };

      LoadView.prototype.socket_events = {
        'registered': 'create_chat',
        'asked': 'wait_for_chat'
      };

      LoadView.prototype.create_chat = function(data) {
        if (data.ok) {
          this.room = data.room;
          Keys.channel = sjcl.random.randomWords(8);
          return View = new ChatView({
            pseudo: this.pseudo,
            room: this.room
          });
        } else {
          return alert("error: " + data.error);
        }
      };

      LoadView.prototype.wait_for_chat = function(data) {
        if (data.ok) {
          return View = new ChatView({
            pseudo: this.pseudo,
            room: this.room,
            waiting: true
          });
        } else {
          return alert("error: " + data.error);
        }
      };

      return LoadView;

    })(Backbone.View);
  });

  $(function() {
    var _ref;
    return window.MsgView = (function(_super) {
      __extends(MsgView, _super);

      function MsgView() {
        _ref = MsgView.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      MsgView.prototype.template = _.template($('#msgTemp').html());

      MsgView.prototype.el = '<p></p>';

      MsgView.prototype.initialize = function(data) {
        this.attr = data;
        return this.$el.html(this.template(this.attr));
      };

      return MsgView;

    })(Backbone.View);
  });

  $(function() {
    var _ref;
    return window.AskView = (function(_super) {
      __extends(AskView, _super);

      function AskView() {
        _ref = AskView.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      AskView.prototype.template = _.template($('#askTemp').html());

      AskView.prototype.el = '<div class="msg_app"></div>';

      AskView.prototype.initialize = function(data) {
        this.attr = data;
        return this.$el.html(this.template(this.attr));
      };

      AskView.prototype.events = {
        'click a': 'accept'
      };

      AskView.prototype.accept = function() {
        socket.emit('confirm', {
          pseudo: this.attr.pseudo,
          hidden_key: Safebook.encrypt_key(this.attr.shared, Keys.channel)
        });
        this.$el.html('<div class="msg_app">' + this.attr.pseudo + ' accepted</div>');
        return false;
      };

      return AskView;

    })(Backbone.View);
  });

  $(function() {
    var _ref;
    return window.ChatView = (function(_super) {
      __extends(ChatView, _super);

      function ChatView() {
        this.on_joiner = __bind(this.on_joiner, this);
        this.on_leaver = __bind(this.on_leaver, this);
        this.on_msg = __bind(this.on_msg, this);
        this.on_ask = __bind(this.on_ask, this);
        _ref = ChatView.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      ChatView.prototype.template = _.template($('#chatTemp').html());

      ChatView.prototype.el = $('body');

      ChatView.prototype.initialize = function(data) {
        var event;
        this.attr = data;
        for (event in this.socket_events) {
          socket.on(event, this[this.socket_events[event]]);
        }
        return this.$el.html(this.template(this.attr));
      };

      ChatView.prototype.add_message = function(attr) {
        return $("#messages").prepend((new MsgView(attr)).el);
      };

      ChatView.prototype.add_invite = function(attr) {
        return $("#messages").prepend((new AskView(attr)).el);
      };

      ChatView.prototype.events = {
        'click button': 'send_message'
      };

      ChatView.prototype.send_message = function() {
        var msg;
        msg = $("textarea").val();
        $("textarea").val('');
        socket.emit('msg', {
          msg: Safebook.hide_message(Keys.channel, msg)
        });
        return this.add_message({
          pseudo: this.attr.pseudo,
          msg: msg
        });
      };

      ChatView.prototype.socket_events = {
        'ask': 'on_ask',
        'accepted': 'on_accepted',
        'msg': 'on_msg',
        'disconnect': 'on_leaver',
        'joiner': 'on_joiner'
      };

      ChatView.prototype.on_ask = function(data) {
        var shared;
        shared = Safebook.get_shared_key(Keys.seckey, data.pubkey);
        return this.add_invite({
          pseudo: data.pseudo,
          shared: shared
        });
      };

      ChatView.prototype.on_accepted = function(data) {
        console.log("accepted");
        Keys.shared = Safebook.get_shared_key(Keys.seckey, data.pubkey);
        Keys.channel = Safebook.decrypt_key(Keys.shared, data.hidden_key);
        return $("#messages").prepend($('<div class="msg_app">Your now in</div>'));
      };

      ChatView.prototype.on_msg = function(data) {
        data.msg = Safebook.load_message(Keys.channel, data.msg);
        return this.add_message(data);
      };

      ChatView.prototype.on_leaver = function(data) {
        return $("#messages").prepend($("<div class=\"msg_app\">" + data.pseudo + " deco</div>"));
      };

      ChatView.prototype.on_joiner = function(data) {
        return $("#messages").prepend($("<div class=\"msg_app\">" + data.pseudo + " join</div>"));
      };

      return ChatView;

    })(Backbone.View);
  });

  $(function() {
    return View = new LoadView();
  });

}).call(this);