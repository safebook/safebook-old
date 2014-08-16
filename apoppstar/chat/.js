// Generated by CoffeeScript 1.6.3
(function() {
  var Entropy, socket,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  socket = io.connect('http://localhost:8004');

  $(function() {
    var LoadView, _ref;
    LoadView = (function(_super) {
      __extends(LoadView, _super);

      function LoadView() {
        _ref = LoadView.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      LoadView.prototype.template = _.template($("#loadTemp").html());

      LoadView.prototype.el = $("body");

      LoadView.prototype.initialize = function() {
        var entropy;
        this.$el.html(this.template());
        entropy = new Entropy();
        entropy.refresh(function(value) {
          return $('#randomness').text(value);
        });
        return entropy.collect();
      };

      return LoadView;

    })(Backbone.View);
    return new LoadView;
  });

  Entropy = (function() {
    function Entropy() {
      this.entropy = 0;
    }

    Entropy.prototype.collect = function() {
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

    Entropy.prototype.add = function(value, estimate, source) {
      this.entropy += estimate;
      sjcl.random.addEntropy(value, estimate, source);
      return this.refresh(this.entropy);
    };

    Entropy.prototype.time_collector = function(e) {
      return this.add((new Date()).valueOf(), 2, "loadtime");
    };

    Entropy.prototype.mouse_collector = function(e) {
      var x, y;
      x = e.x || e.clientX || e.offsetX || 0;
      y = e.y || e.clientY || e.offsetY || 0;
      return this.add([x, y], 2, "mouse");
    };

    Entropy.prototype.keys_collector = function(e) {
      var keyCode, ms;
      ms = new Date().getMilliseconds();
      keyCode = e.keyCode || e.which;
      return this.add([ms, keyCode], 2, "keys");
    };

    return Entropy;

  })();

}).call(this);
