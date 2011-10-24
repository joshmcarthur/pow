(function() {
  var Installer, InstallerFile, async, chown, fs, initdSource, mkdirp, path, resolvconfSource, sys;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  async = require("async");
  fs = require("fs");
  path = require("path");
  mkdirp = require("./util").mkdirp;
  chown = require("./util").chown;
  sys = require("sys");
  initdSource = require("./templates/installer/pow_initd");
  resolvconfSource = require("./templates/installer/resolvconf_tail");
  InstallerFile = (function() {
    function InstallerFile(path, source, root, mode, symlink_path) {
      this.path = path;
      this.root = root != null ? root : false;
      this.mode = mode != null ? mode : 0644;
      this.symlink_path = symlink_path != null ? symlink_path : false;
      this.setPermissions = __bind(this.setPermissions, this);
      this.setOwnership = __bind(this.setOwnership, this);
      this.symlinkFile = __bind(this.symlinkFile, this);
      this.writeFile = __bind(this.writeFile, this);
      this.vivifyPath = __bind(this.vivifyPath, this);
      this.source = source.trim();
    }
    InstallerFile.prototype.isStale = function(callback) {
      return path.exists(this.path, __bind(function(exists) {
        if (exists) {
          return fs.readFile(this.path, "utf8", __bind(function(err, contents) {
            if (err) {
              return callback(true);
            } else {
              return callback(this.source !== contents.trim());
            }
          }, this));
        } else {
          return callback(true);
        }
      }, this));
    };
    InstallerFile.prototype.vivifyPath = function(callback) {
      return mkdirp(path.dirname(this.path), callback);
    };
    InstallerFile.prototype.writeFile = function(callback) {
      return fs.writeFile(this.path, this.source, "utf8", callback);
    };
    InstallerFile.prototype.symlinkFile = function(callback) {
      return fs.symlinkFile(this.path, this.symlink_path, callback);
    };
    InstallerFile.prototype.setOwnership = function(callback) {
      if (this.root) {
        return chown(this.path, "root:admin", callback);
      } else {
        return callback(false);
      }
    };
    InstallerFile.prototype.setPermissions = function(callback) {
      return fs.chmod(this.path, this.mode, callback);
    };
    InstallerFile.prototype.install = function(callback) {
      if (this.symlink_path) {
        return async.series([this.vivifyPath, this.writeFile, this.symlinkFile, this.setOwnership, this.setPermissions], callback);
      } else {
        return async.series([this.vivifyPath, this.writeFile, this.setOwnership, this.setPermissions], callback);
      }
    };
    return InstallerFile;
  })();
  module.exports = Installer = (function() {
    Installer.getInitdInstaller = function(configuration) {
      var files;
      this.configuration = configuration;
      files = [];
      files.push(new InstallerFile("~/.pow_application/installed/initd", initdSource(this.configuration), true, 0644, "/etc/init.d/pow"));
      files.push(new InstallerFile("~/.pow_application/installed/resolvconf_tail", resolvconfSource(this.configuration), true, 0644, "/etc/resolvconf/resolvconf.conf.d/tail"));
      return new Installer(files);
    };
    function Installer(files) {
      this.files = files != null ? files : [];
    }
    Installer.prototype.getStaleFiles = function(callback) {
      return async.select(this.files, function(file, proceed) {
        return file.isStale(proceed);
      }, callback);
    };
    Installer.prototype.needsRootPrivileges = function(callback) {
      return this.getStaleFiles(function(files) {
        return async.detect(files, function(file, proceed) {
          return proceed(file.root);
        }, function(result) {
          return callback(result != null);
        });
      });
    };
    Installer.prototype.install = function(callback) {
      return this.getStaleFiles(function(files) {
        return async.forEach(files, function(file, proceed) {
          return file.install(function(err) {
            if (!err) {
              sys.puts(file.path);
            }
            return proceed(err);
          });
        }, callback);
      });
    };
    return Installer;
  })();
}).call(this);
