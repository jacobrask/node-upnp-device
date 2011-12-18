# UPnP Devices.

"use strict"

Device = require './Device'

exports.createDevice = (reqType, name, address) ->
    type = reqType.toLowerCase()
    unless type of devices
        device = new EventEmitter
        device.emit 'error', new Error "UPnP device of type #{type} is not yet implemented."
        return device
    new devices[type](name, address)


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
