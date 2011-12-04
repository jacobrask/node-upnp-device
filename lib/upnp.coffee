# UPnP Devices.

"use strict"

async = require 'async'
{EventEmitter} = require 'events'

httpServer = require './httpServer'
helpers = require './helpers'
ssdp = require './ssdp'

exports.createDevice = (reqType, name, address) ->
    type = reqType.toLowerCase()
    unless type of devices
        device = new EventEmitter
        device.emit 'error', new Error "UPnP device of type #{type} is not yet implemented."
        return device
    new devices[type](name, address)

class Device extends EventEmitter

    constructor: (@name, @address) ->
        @schemaPrefix = 'urn:schemas-upnp-org'
        @schemaVersion = '1.0'
        @upnpVersion = '1.0'
        @init()

    # Asynchronous operations to get some device properties.
    init: (callback) ->
        async.parallel
            uuid: (callback) => helpers.getUuid @type, @name, callback
            address: (callback) =>
                if @address?
                    callback null, @address
                else
                    helpers.getNetworkIP callback
            port: (callback) => httpServer.start.call @, callback
            (err, res) =>
                return device.emit 'error', err if err?
                @uuid = "uuid:#{res.uuid}"
                @address = res.address
                @httpPort = res.port
                @emit 'ready'
        @

    announce: (callback) ->
        ssdp.start.call @
        do callback if callback?
        @

services =
    ConnectionManager: require './services/ConnectionManager'
    ContentDirectory: require './services/ContentDirectory'

class MediaServer extends Device

    constructor: ->
        super
        @type = 'MediaServer'
        @version = 1
        @services = {}
        new services[type](@) for type in ['ConnectionManager','ContentDirectory']

devices = mediaserver: MediaServer
