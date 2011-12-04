# UPnP Devices.

"use strict"

async = require 'async'
eventEmitter = require('events').EventEmitter.prototype
log = new (require 'log')
require './utils'

httpServer = require './httpServer'
helpers = require './helpers'
ssdp = require './ssdp'
utils = require './utils'

services =
    ContentDirectory: require './services/ContentDirectory'
    ConnectionManager: require './services/ConnectionManager'

exports.createDevice = (reqType, name, address) ->
    type = reqType.toLowerCase()

    device = newDevice(name or type, type)
    unless device.type?
        device.emit 'error', new Error "UPnP device of type #{type} is not yet implemented."
        return device

    device.address = address if address?

    device
        .addServices()
        .init (err, res) ->
            return device.emit 'error', err if err?
            Object.defineProperty device, 'uuid', value: "uuid:#{res.uuid}"
            device.address = res.address
            device.httpPort = res.port
            device.emit 'ready'

    device

newDevice = (name, type) ->

    init = (callback) ->
        # Asynchronous operations to get some device properties.
        async.parallel(
            uuid: (callback) => helpers.getUuid @type, @name, callback
            address: (callback) =>
                if @address?
                    callback null, @address
                else
                    helpers.getNetworkIP callback
            port: (callback) => httpServer.start.call @, callback
            callback)
        @

    announce = (callback) ->
        ssdp.start.call @
        do callback if callback?
        @

    addServices = ->
        @services = {}
        for st in @serviceTypes
            @services[st] = Object.create services[st], device: { value: @ }
        @

    baseProps =
        name: { value: name, enumerable: yes }
        announce: { value: announce, enumerable: yes }
        upnpVersion: { value: '1.0' }
        addServices: { value: addServices }
        init: { value: init }

    typeProps =
        mediaserver:
            type: { value: 'MediaServer', enumerable: yes }
            version: { value: 1, enumerable: yes }
            schemaPrefix: { value: 'urn:schemas-upnp-org' }
            schemaVersion: { value: '1.0' }
            serviceTypes: { value: [ 'ConnectionManager', 'ContentDirectory' ] }

    Object.create(eventEmitter
        if typeProps[type]?
            utils.extend baseProps, typeProps[type]
        else
            baseProps
    )
