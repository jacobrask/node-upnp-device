# Helper functions not large enough to warrant separate modules.

fs     = require 'fs'
uuid   = require 'node-uuid'
{exec} = require 'child_process'

# Run `export NODE_DEBUG=upnp-device` to activate debugging messages.
debug = exports.debug =
    if process.env.NODE_DEBUG && /upnp-device/.test process.env.NODE_DEBUG
        (args...) -> console.error 'UPNP:', args...
    else
        ->


# We need to get the server's internal network IP to send out in SSDP messages.
# Only works in Linux and (probably) Mac.
exports.getNetworkIP = (callback) ->
    exec 'ifconfig', (err, stdout, sterr) ->
        if process.platform is 'darwin'
            filterRE = /\binet\s+([^\s]+)/g
        else
            filterRE = /\binet\b[^:]+:\s*([^\s]+)/g
        matches = stdout.match(filterRE)

        # Filter out localhost IPs.
        callback err, matches
            .map((match) -> match.replace filterRE, '$1')
            .filter(
                (match) ->
                    !/^(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test match
            )[0]


# Try to persist UUID, otherwise Control Points won't know it's the same
# device on restarts. We attempt to store UUIDs as JSON in a file called
# **upnp-uuid** in upnp-device's root folder, but err gracefully by
# returning a new uuid if the file cannot be read/written.
# Call with Device object bound to `@`.
exports.getUuid = (callback) ->
    uuidFile = "#{__dirname}/../upnp-uuid"
    fs.readFile uuidFile, 'utf8', (err, data) =>
        data = JSON.parse(data or "{}")
        # Found UUID for a device with same type and name.
        if data[@type]?[@name]
            callback null, data[@type][@name]
        # File can't be read or matching UUID isn't found.
        # Return a new UUID instead.
        else
            uuid = uuid()
            data ?= {}
            data[@type] ?= {}
            data[@type][@name] = uuid
            # We don't care if the save has finished or succeeded
            # before we call back.
            fs.writeFile uuidFile, JSON.stringify(data)
            callback null, uuid
