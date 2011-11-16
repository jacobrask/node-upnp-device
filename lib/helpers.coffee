# Helper functions not large enough to warrant separate modules.
fs     = require 'fs'
uuid   = require 'node-uuid'
{exec} = require 'child_process'

(console[c] = ->) for c in ['log','info'] unless /upnp-device/.test process.env.NODE_DEBUG

# We need to get the server's internal network IP to send out in SSDP messages.
# Only works in Linux and (probably) Mac.
exports.getNetworkIP = (callback) ->
    exec 'ifconfig', (err, stdout, sterr) ->
        if process.platform is 'darwin'
            filterRE = /\binet\s+([^\s]+)/g
        else
            filterRE = /\binet\b[^:]+:\s*([^\s]+)/g
        matches = stdout.match(filterRE)

        match = matches
            .map((match) -> match.replace filterRE, '$1')
            .filter(
                (match) ->
                    !/^(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test match
            )[0]
        console.info "`ifconfig` returned '#{matches}', after filtering out localhost IPs, '#{match}' will be used."
        callback err, match


# Try to persist UUID, otherwise Control Points won't know it's the same
# device on restarts. We attempt to store UUIDs as JSON in a file called
# **upnp-uuid** in upnp-device's root folder, but err gracefully by
# returning a new uuid if the file cannot be read/written.
exports.getUuid = (callback) ->
    uuidFile = "#{__dirname}/../upnp-uuid"
    fs.readFile uuidFile, 'utf8', (err, data) =>
        data = JSON.parse(data or "{}")
        if data[@type]?[@name]
            console.info 'Found UUID for a device with same type and name.'
            callback null, data[@type][@name]
        else
            console.info 'No existing UUID for this device was found.'
            console.warn err.msg if err
            console.info 'Generating and returning a new UUID.'
            uuid = uuid()
            data ?= {}
            data[@type] ?= {}
            data[@type][@name] = uuid
            # We don't care if the save has finished/succeeded before callback.
            fs.writeFile uuidFile, JSON.stringify(data)
            callback null, uuid

# Turn each key/value pair into separate objects. Mostly used for XML element
# creation. Optionally takes an array to push elements to.
exports.objToArr = (obj, arr) ->
    arr ?= []
    Object.keys(obj).map (key) ->
        o = {}
        o[key] = obj[key]
        arr.push o
    return arr
