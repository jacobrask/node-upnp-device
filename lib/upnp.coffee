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

    constructor: (@name, address) ->
        @address = address if address?
        @schemaPrefix = 'urn:schemas-upnp-org'
        @schemaVersion = '1.0'
        @upnpVersion = '1.0'

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
                @emit 'ready'

    announce: (callback) ->
        ssdp.start.call @
        do callback if callback?
        @

    addService: (type) ->
        (@services?={})[type] = new services[type](@)
        @emit 'newService', type

services =
    ConnectionManager: require './services/ConnectionManager'
    ContentDirectory: require './services/ContentDirectory'


class MediaServer extends Device
    constructor: ->
        super
        @type = 'MediaServer'
        @version = 1
        @addService type for type in ['ConnectionManager','ContentDirectory']
        @init()

    addMedia: ->
        @services.ContentDirectory.addMedia arguments...


devices = mediaserver: MediaServer
