async         = require 'async'
fs            = require 'fs'
{print}       = require 'sys'
{spawn, exec} = require 'child_process'

build = (watch, callback) ->
  if typeof watch is 'function'
    callback = watch
    watch = false
  options = ['-c', '-o', 'lib', 'src']
  options.unshift '-w' if watch

  coffee = spawn 'coffee', options
  coffee.stdout.on 'data', (data) -> print data.toString()
  coffee.stderr.on 'data', (data) -> print data.toString()
  coffee.on 'exit', (status) -> callback?() if status is 0

buildTemplates = (callback) ->
  eco = require 'eco'
  compile = (name) ->
    (callback) ->
      fs.readFile "src/templates/#{name}.eco", "utf8", (err, data) ->
        if err then callback err
        else fs.writeFile "lib/templates/#{name}.js", eco.compile(data), callback

  async.parallel [
    compile("http_server/application_not_found.html")
    compile("http_server/error_starting_application.html")
    compile("http_server/layout.html")
    compile("http_server/proxy_error.html")
    compile("http_server/rackup_file_missing.html")
    compile("http_server/welcome.html")
    compile("installer/cx.pow.firewall.plist")
    compile("installer/cx.pow.powd.plist")
    compile("installer/resolver")
  ], callback

task 'docs', 'Generate annotated source code with Docco', ->
  fs.readdir 'src', (err, contents) ->
    files = ("src/#{file}" for file in contents when /\.coffee$/.test file)
    docco = spawn 'docco', files
    docco.stdout.on 'data', (data) -> print data.toString()
    docco.stderr.on 'data', (data) -> print data.toString()
    docco.on 'exit', (status) -> callback?() if status is 0

task 'build', 'Compile CoffeeScript source files', ->
  build()
  buildTemplates()

task 'watch', 'Recompile CoffeeScript source files when modified', ->
  build true

task 'test', 'Run the Pow test suite', ->
  build ->
    process.env["RUBYOPT"]  = "-rubygems"
    process.env["NODE_ENV"] = "test"
    require.paths.unshift __dirname + "/lib"

    {reporters} = require 'nodeunit'
    process.chdir __dirname
    reporters.default.run ['test']

task 'install', 'Install pow configuration files', ->
  sh = (command, callback) ->
    exec command, (err, stdout, stderr) ->
      if err
        console.error stderr
        callback err
      else
        callback()

  createHostsDirectory = (callback) ->
    sh 'mkdir -p "$HOME/.pow_application/Hosts"', (err) ->
      fs.stat "#{process.env['HOME']}/.pow", (err) ->
        if err then sh 'ln -s "$HOME/.pow_application/Hosts" "$HOME/.pow"', callback
        else callback()

  installLocal = (callback) ->
    console.error "*** Installing local configuration files..."
    sh "./bin/pow --install-local", callback

  installSystem = (callback) ->
    exec "./bin/pow --install-system --dry-run", (needsRoot) ->
      if needsRoot
        console.error "*** Installing system configuration files as root..."
        sh "sudo ./bin/pow --install-system", (err) ->
          if err
            callback err
          else
            sh "sudo ln -s $HOME/.pow_application/lib/templates/pow_initd.js /etc/init.d/pow", callback
      else
        callback()

  async.parallel [createHostsDirectory, installLocal, installSystem], (err) ->
    throw err if err
    console.error "*** Installed"

task 'start', 'Start pow server', ->
  console.error "*** Starting the Pow server..."
  exec "/etc/init.d/pow start", (err, stdout, stderr) ->
    console.error stderr if err

task 'stop', 'Stop pow server', ->
  console.error "*** Stopping the Pow server..."
  exec "/etc/init.d/pow stop", (err, stdout, stderr) ->
    console.error stderr if err
