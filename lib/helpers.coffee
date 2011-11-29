"use strict"

{exec} = require 'child_process'
fs = require 'fs'

log = new (require 'log')
uuid = require 'node-uuid'

# We need to get the server's internal network IP to send out in SSDP messages.
# Only works on Linux and (probably) Mac.
exports.getNetworkIP = (callback) ->
    exec 'ifconfig', (err, stdout, sterr) ->
        if process.platform is 'darwin'
            filterRE = /\binet\s+([^\s]+)/g
        else
            filterRE = /\binet\b[^:]+:\s*([^\s]+)/g
        isLocal = (address) -> /^(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test address
        matches = stdout.match(filterRE)
        match = (match.replace(filterRE, '$1') for match in matches when !isLocal match)
        log.debug "`ifconfig` returned '#{matches}', after filtering out localhost IPs, '#{match}' will be used."
        callback err, match

# Attempt UUID persistance of devices across restarts.
# Returns a fresh UUID if no existing UUID was found.
exports.getUuid = (type, name, callback) ->

    # UUID's are stored in a JSON file in upnp-device's root folder.
    uuidFile = "#{__dirname}/../upnp-uuid"
    fs.readFile uuidFile, 'utf8', (err, file) ->
        log.notice err.message if err
        data = JSON.parse(file or "{}")
        unless data[type]?[name]
            (data[type]?={})[name] = uuid()
            fs.writeFile uuidFile, JSON.stringify(data)
        # Call back with UUID even if (and before) read/write fails.
        callback null, data[type][name]
