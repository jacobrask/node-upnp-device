# Implements [UPnP Device Architecture version 1.0] [1]
#
# [1]: http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

fs   = require 'fs'
os   = require 'os'
uuid = require 'node-uuid'

protocol = require '../protocol'
ssdp = require '../ssdp'
httpServer = require '../httpServer'
xml  = require '../xml'

# Using CoffeeScript's `class` for convenience.
class Device

    # Note the callback; constructor is asynchronous.
    constructor: (@name, callback) ->
        @name ?= "Generic #{@type} device"
        @schema =
            prefix: 'urn:schemas-upnp-org'
            version: '1.0'
            upnpVersion: '1.0'
        @_getUuid (err, uuid) =>
            @uuid = "uuid:#{uuid}"
            callback null, @
        @

    # Start HTTP server and SSDP handler.
    start: (callback) ->
        @_startServer (err, serverInfo) =>
            @httpAddress = serverInfo.address
            @httpPort = serverInfo.port
            ssdp.listen @
            ssdp.announce @
            callback null, ':-)'
        @

    _startServer: httpServer.start
    _buildDescription: xml.buildDescription

    # Try to persist UUID, otherwise Control Points won't know it's the same
    # device on restarts. We attempt to store UUIDs as JSON in a file called
    # **upnp-uuid** in upnp-device's root folder, but err gracefully by
    # returning a new uuid if the file cannot be read/written.
    _getUuid: (callback) ->
        uuidFile = "#{__dirname}/../../upnp-uuid"
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



module.exports = Device
