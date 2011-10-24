module.exports = function(__obj) {
  var _safe = function(value) {
    if (typeof value === 'undefined' && value == null)
      value = '';
    var result = new String(value);
    result.ecoSafe = true;
    return result;
  };
  return (function() {
    var __out = [], __self = this, _print = function(value) {
      if (typeof value !== 'undefined' && value != null)
        __out.push(value.ecoSafe ? value : __self.escape(value));
    }, _capture = function(callback) {
      var out = __out, result;
      __out = [];
      callback.call(this);
      result = __out.join('');
      __out = out;
      return _safe(result);
    };
    (function() {
      _print(_safe('#!/bin/sh\n\nBEGIN INIT INFO\n\nProvides:     pow\n\n\n\nRequired-Start:   $remote_fs $syslog\n\n\n\nRequired-Stop:    $remote_fs $syslog\n\n\n\nDefault-Start:    2 3 4 5\n\n\n\nDefault-Stop:     1\n\n\n\nEND INIT INFO\n\n\n\nEXEC='));
      _print(this.bin);
      _print(_safe('\nPIDFILE=/var/run/pow.pid\nOPTS=""\n\n\n\nset -e\n\n\n\n. /lib/lsb/init-functions\n\n\n\n\ncase "$1" in\n  start)\n    logdaemonmsg "Starting Pow" "pow"\n    if start-stop-daemon --start --quiet --oknodo --make-pidfile --background --pidfile $PIDFILE --exec $EXEC -- $OPTS; then\n        logendmsg 0\n    else\n        logendmsg 1\n    fi\n    ;;\n  stop)\n    logdaemonmsg "Stopping Pow" "pow"\n    if start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE; then\n        logendmsg 0\n    else\n        logendmsg 1\n    fi\n    ;;\n\n*)\n        log_action_msg "Usage: /etc/init.d/pow {start|stop}"\n        exit 1\nesac\n\n\n\nexit 0\n'));
    }).call(this);
    
    return __out.join('');
  }).call((function() {
    var obj = {
      escape: function(value) {
        return ('' + value)
          .replace(/&/g, '&amp;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .replace(/"/g, '&quot;');
      },
      safe: _safe
    }, key;
    for (key in __obj) obj[key] = __obj[key];
    return obj;
  })());
};