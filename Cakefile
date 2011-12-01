task 'test', 'Run the test suite', ->
    require('nodeunit').reporters.default.run ['./test']
    
task 'docs', 'Generate annotated source code with Docco', ->
    fs            = require 'fs'
    {print}       = require 'util'
    {spawn} = require 'child_process'
    fs.readdir 'lib', (err, contents) ->
        files = ("lib/#{file}" for file in contents when /\.coffee$/.test file)
        docco = spawn 'docco', files
        docco.stdout.on 'data', (data) -> print data.toString()
        docco.stderr.on 'data', (data) -> print data.toString()
