# UPnP Devices.

{EventEmitter} = require 'events'
async      = require 'async'
log   = new (require 'log')()
httpServer = require './httpServer'
helpers    = require './helpers'
ssdp       = require './ssdp'
xml        = require './xml'

exports.createDevice = (type, name, address) ->
    unless type of devices
        return new Error "UPnP device of type #{type} is not yet implemented."

    device = Object.create devices[type],
        name: { value: name, enumerable: true }
        type: { value: type, enumerable: true }

    device.address = address if address?

    init device

    device


Device = Object.create new EventEmitter

Device.announce = (callback = ->) ->
    ssdp.start.call @
    do callback
    @

MediaServer = Object.create Device,
    version: { value: 1 }
    schemaPrefix: { value: 'urn:schemas-upnp-org' }
    schemaVersion: { value: '1.0' }
    upnpVersion: { value: '1.0' }


# Need an object to reference a device by its type.
devices = MediaServer: MediaServer

# Initiate a device.
init = (device, callback) ->
    async.parallel(
        uuid: (callback) -> helpers.getUuid device.type, device.name, callback
        address: (callback) ->
            if device.address?
                callback null, device.address
            else
                helpers.getNetworkIP callback
        port: (callback) -> httpServer.start.call device, callback
        (err, res) ->
            return device.emit 'error', err if err?
            Object.defineProperty device, 'uuid', value: "uuid:#{res.uuid}"
            device.address = res.address
            device.httpPort = res.port
            device.emit 'ready'
    )
