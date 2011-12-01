"use strict"

fs = require 'fs'
{parseIP} = require '../lib/helpers'

exports["Get local IP on Mac"] = (test) ->
    fs.readFile './test/fixtures/macifconfig.txt', 'utf8', (err, file) ->
        process.platform = 'darwin'
        parseIP file, (err, ip) ->
            test.ifError err
            test.equal ip, "10.0.1.2"
            test.done()
        
exports["Get local IP on Linux"] = (test) ->
    fs.readFile './test/fixtures/linuxifconfig.txt', 'utf8', (err, file) ->
        process.platform = 'linux'
        parseIP file, (err, ip) ->
            test.ifError err
            test.equal ip, "192.168.9.3"
            test.done()
        
exports["Get local IP on Windows"] = (test) ->
    process.platform = 'windows'
    parseIP '', (err, ip) ->
        test.ifError err
        test.equal ip, "192.168.0.1"
        test.done()
