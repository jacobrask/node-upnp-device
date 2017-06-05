# UPnP Media Server.
# Adds static properties and public API methods. Also see [specification] [1].
#
# [1]: http://upnp.org/specs/av/av1/

"use strict"

# Extends generic [`Device`](Device.html) class.
UPNP = require '../index.js'

class MyDevice extends UPNP.Device

  constructor: -> super

  serviceTypes: [ 'MyService' ]

  serviceReferences:
      MyService: require './MyService'

  type: 'MyDevice' # The type of device, this is a required!
  version: 1 # The version number of the device, default value is 1.
  manufacturer: 'MyManufacturer' # The manufacturer of the device, default value is 'UPnP Device for Node.js'.
  friendlyName: 'MyDeviceFriendlyName' # The friendly name of the device, default value is the name supplied to createMyDevice plus hostname.

module.exports = MyDevice
