# UPnP Devices.

"use strict"

async = require 'async'

httpServer = require './httpServer'
helpers = require './helpers'
ssdp = require './ssdp'
DeviceControlProtocol = require './protocol'
utils = require './utils'
xml = require './xml'

exports.createDevice = (reqType, name, address) ->
    type = reqType.toLowerCase()
    unless type of devices
        device = new EventEmitter
        device.emit 'error', new Error "UPnP device of type #{type} is not yet implemented."
        return device
    new devices[type](name, address)


class Device extends DeviceControlProtocol

    constructor: (@name, address) ->
        super
        @address = address if address?

    # Asynchronous operations to get and set some device properties.
    init: (callback) ->
        async.parallel
            uuid: (callback) => helpers.getUuid @type, @name, callback
            address: (callback) =>
                return callback null, @address if @address?
                helpers.getNetworkIP callback
            port: (callback) => httpServer.start.call @, callback
            (err, res) =>
                return device.emit 'error', err if err?
                @uuid = "uuid:#{res.uuid}"
                @address = res.address
                @httpPort = res.port
                ssdp.start.call @
                @emit 'ready'

    addService: (type) ->
        (@services?={})[type] = new services[type](@)
        @emit 'newService', type

services =
    ConnectionManager: require './services/ConnectionManager'
    ContentDirectory: require './services/ContentDirectory'


class MediaServer extends Device
    constructor: ->
        super
        @addService type for type in ['ConnectionManager','ContentDirectory']
        @init()

    type: 'MediaServer'
    version: 1

    addMedia: ->
        @services.ContentDirectory.addMedia arguments...


devices = mediaserver: MediaServer
