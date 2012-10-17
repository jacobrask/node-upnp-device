# UPnP Media Server.
# Adds static properties and public API methods. Also see [specification] [1].
#
# [1]: http://upnp.org/specs/av/av1/

"use strict"

_ = require '../utils'

# Extends generic [`Device`](Device.html) class.
Device = require './Device'

class BinaryLight extends Device

  constructor: -> super

  serviceTypes: [ 'SwitchPower' ]

  type: 'BinaryLight'
  version: 1

module.exports = BinaryLight
