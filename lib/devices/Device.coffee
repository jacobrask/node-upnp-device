# Implements [UPnP Device Architecture version 1.0] [1]
#
# [1]: http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

helpers    = require '../helpers'
httpServer = require '../httpServer'
ssdp       = require '../ssdp'
xml        = require '../xml'

# Using CoffeeScript's `class` for convenience.
class Device

    # Constructor is asynchronous.
    constructor: (@name, callback) ->
        @name ?= "Generic #{@type} device"
        @schema =
            prefix: 'urn:schemas-upnp-org'
            version: '1.0'
            upnpVersion: '1.0'

        helpers.getUuid.call @, (err, uuid) =>
            @uuid = "uuid:#{uuid}"
            callback null, @
        @

    # Start HTTP server and SSDP handler.
    start: (callback) ->
        httpServer.start.call @, (err, serverInfo) =>
            @httpAddress = serverInfo.address
            @httpPort = serverInfo.port
            ssdp.listen @
            ssdp.announce @
            callback null, ':-)'
        @

    _buildDescription: xml.buildDescription


module.exports = Device
