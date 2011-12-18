# UPnP Media Server. See [specification] [1].
#
# [1]: http://upnp.org/specs/av/av1/

"use strict"

Device = require './Device'

class MediaServer extends Device

    constructor: ->
        super
        @addService type for type in [ 'ConnectionManager', 'ContentDirectory' ]
        @init()

    type: 'MediaServer'
    version: 1

    addMedia: -> @services.ContentDirectory.addMedia arguments...


module.exports = MediaServer
