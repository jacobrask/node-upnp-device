# UPnP Devices.
#
# vim: ts=2 sw=2 sts=2

"use strict"

{EventEmitter} = require 'events'

devices = mediaserver: require './devices/MediaServer'

exports.createDevice = (reqType, name, address) ->
  type = reqType.toLowerCase()
  unless type of devices
    device = new EventEmitter
    device.emit 'error', new Error "UPnP device of type #{type} is not yet implemented."
    return device
  new devices[type] name, address
