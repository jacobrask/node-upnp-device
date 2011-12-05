"use strict"

log = new (require 'log')
utils = require './utils'

{exec} = require 'child_process'
# We need to get the server's internal network IP to send out in SSDP messages.
# Only works on Linux and Mac.
do ->
    parseIP = exports.parseIP = (stdout) ->
        switch process.platform
            when 'darwin'
                filterRE = /\binet\s+([^\s]+)/g
            when 'linux'
                filterRE = /\binet\b[^:]+:\s*([^\s]+)/g
            else
                return null
        isLocal = (address) -> /(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test address
        matches = stdout.match(filterRE) or ''
        (match.replace(filterRE, '$1') for match in matches when !isLocal match)[0]

    exports.getNetworkIP = (callback) ->
        exec 'ifconfig', (err, stdout) ->
            log.notice err.message if err?
            ip = parseIP stdout
            callback(
                if ip? then null else new Error "IP address could not be retrieved."
                ip)

fs = require 'fs'
makeUuid = require 'node-uuid'
# Attempt UUID persistance of devices across restarts.
exports.getUuid = (type, name, callback) ->
    uuidFile = "#{__dirname}/../upnp-uuid"
    fs.readFile uuidFile, 'utf8', (err, file) ->
        log.notice err.message if err?
        uuid = utils.parseJSON(file)[type]?[name]
        unless uuid?
            log.debug "Returning new uuid #{uuid}"
            ((data={})[type]={})[name] = uuid = makeUuid()
            fs.writeFile uuidFile, JSON.stringify data
        # Always call back with UUID, existing or new.
        callback null, uuid
