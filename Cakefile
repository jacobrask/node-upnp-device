{exec} = require 'child_process'

task 'test', 'Run tests', ->
    exec 'coffee test/*.coffee', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
