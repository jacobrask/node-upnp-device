# Implements [UPnP Device Architecture version 1.0] [1]
#
# [1]: http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

fs   = require 'fs'
os   = require 'os'
uuid = require 'node-uuid'
xml  = require 'xml'

protocol = require '../protocol'
ssdp = require '../ssdp'
httpServer = require '../httpServer'

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
        @startServer (err, serverInfo) =>
            @httpAddress = serverInfo.address
            @httpPort = serverInfo.port
            ssdp.listen @
            ssdp.announce @
            callback null, ':-)'
        @

    startServer: httpServer.start

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

    # build device description element
    buildDescription: (callback) ->
        desc = '<?xml version="1.0" encoding="utf-8"?>'
        desc += xml [
                root: [
                    _attr:
                        xmlns: protocol.makeNameSpace()
                    { specVersion: @buildSpecVersion() }
                    { device: @buildDevice() }
                ]
            ]
        callback null, desc

    # build spec version element
    buildSpecVersion: ->
        [ { major: @schema.upnpVersion.split('.')[0] }
          { minor: @schema.upnpVersion.split('.')[1] } ]

    # build device element
    buildDevice: ->
        [ { deviceType: protocol.makeDeviceType(@type, @version) }
          { friendlyName: "#{@name} @ #{os.hostname()}".substr(0, 64) }
          { manufacturer: 'node-upnp-device' }
          { modelName: @name.substr(0, 32) }
          { UDN: @uuid }
          { serviceList: @buildServiceList() } ]

    # build an array of all service elements
    buildServiceList: ->
        for serviceType in Object.keys(@services)
            { service: @buildService serviceType }

    # build an array of elements to generate a service XML element
    buildService: (serviceType) ->
        [ { serviceType: protocol.makeServiceType(serviceType, @version) }
          { serviceId: 'urn:upnp-org:serviceId:' + serviceType }
          { SCPDURL: '/service/description/' + serviceType }
          { controlURL: '/service/control/' + serviceType }
          { eventSubURL: '/service/event/' + serviceType } ]

module.exports = Device
