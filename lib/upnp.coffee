# UPnP Devices.

"use strict"

async = require 'async'
eventEmitter = require('events').EventEmitter.prototype
log = new (require 'log')
require './utils'

httpServer = require './httpServer'
helpers = require './helpers'
ssdp = require './ssdp'


exports.createDevice = (type, name, address) ->
    type = type.toLowerCase()
    unless type of devices
        device = Object.extend {}, eventEmitter
        device.emit 'error', new Error "UPnP device of type #{type} is not yet implemented."
        return device

    device = Object.create devices[type]

    device.name = name or type
    device.address = address if address?

    init device, (err, res) ->
        return device.emit 'error', err if err?
        Object.defineProperty device, 'uuid', value: "uuid:#{res.uuid}"
        device.address = res.address
        device.httpPort = res.port
        device.emit 'ready'

    device

device = Object.extend {}, eventEmitter

Object.defineProperties device,
    upnpVersion: { value: '1.0', enumerable: yes }

device.announce = (callback) ->
    ssdp.start.call @
    do callback if callback?
    @

device.services = {}

mediaserver = Object.create device,
    type: { value: 'MediaServer', enumerable: yes }
    version: { value: 1, enumerable: yes }
    schemaPrefix: { value: 'urn:schemas-upnp-org', enumerable: yes }
    schemaVersion: { value: '1.0', enumerable: yes }

ContentDirectory = require './services/ContentDirectory'
ConnectionManager = require './services/ConnectionManager'

mediaserver.services.ContentDirectory  = Object.create new ContentDirectory(mediaserver), device: { value: mediaserver }
mediaserver.services.ConnectionManager = Object.create new ConnectionManager(mediaserver), device: { value: mediaserver }

# Need an object to reference a device by its type.
devices = mediaserver: mediaserver

# Asynchronous operations to get some device properties.
init = (device, callback) ->
    async.parallel(
        uuid: (callback) -> helpers.getUuid device.type, device.name, callback
        address: (callback) ->
            if device.address?
                callback null, device.address
            else
                helpers.getNetworkIP callback
        port: (callback) -> httpServer.start.call device, callback
        callback)
