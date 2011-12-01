"use strict"

{exec} = require 'child_process'
fs = require 'fs'

log = new (require 'log')
makeUuid = require 'node-uuid'

# We need to get the server's internal network IP to send out in SSDP messages.
# Only works on Linux and Mac.
do ->
    ipErr = new Error "IP address could not be retrieved. Please supply an address when starting the application."
    parseIP = exports.parseIP = (stdout, callback) ->
        switch process.platform
            when 'darwin'
                filterRE = /\binet\s+([^\s]+)/g
            when 'linux'
                filterRE = /\binet\b[^:]+:\s*([^\s]+)/g
            else
                return callback ipErr
        isLocal = (address) -> /(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test address
        matches = stdout.match(filterRE) or ''
        match = (match.replace(filterRE, '$1') for match in matches when !isLocal match)[0]
        callback (if !match? then ipErr else null), match

    exports.getNetworkIP = (callback) ->
        exec 'ifconfig', (err, stdout) ->
            return callback ipErr if err?
            parseIP stdout, callback

# Attempt UUID persistance of devices across restarts.
# Returns a fresh UUID if no existing UUID was found.
do ->
    # UUID's are stored in a JSON file in upnp-device's root folder.
    uuidFile = "#{__dirname}/../upnp-uuid"

    readUuidFile = (callback) -> fs.readFile uuidFile, 'utf8', callback
    writeUuidFile = (data) -> fs.writeFile uuidFile, JSON.stringify data

    parseUuidFile = exports.parseUuidFile = (file, type, name, callback) ->
        data = JSON.parse(file or "{}")
        unless data[type]?[name]
            callback new Error "#{type} device #{name} not found in UUID file."
        else
            callback null, data[type][name]

    exports.getUuid = (type, name, callback) ->
        readUuidFile (err, file) ->
            log.notice err.message if err?
            parseUuidFile file, type, name, (err, uuid) ->
                if err?
                    log.debug err.message
                    ((data={})[type]={})[name] = uuid = makeUuid()
                    writeUuidFile data
                # Call back with UUID even if (and before) read/write fails.
                callback null, uuid
