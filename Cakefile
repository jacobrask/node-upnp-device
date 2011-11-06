{exec} = require 'child_process'

task 'build', 'Compile CoffeeScript to JavaScript', ->
    exec 'coffee --compile --output lib/ src/', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr

task 'test', 'Run tests', ->
    exec 'coffee test/*.coffee', (err, stdout, stderr) ->
        throw err if err
        console.log stdout + stderr
