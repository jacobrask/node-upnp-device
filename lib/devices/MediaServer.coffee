# UPnP Media Server. See [specification] [1].
#
# [1]: http://upnp.org/specs/av/av1/

"use strict"

Device = require './Device'

services =
    ConnectionManager: require '../services/ConnectionManager'
    ContentDirectory:  require '../services/ContentDirectory'

class MediaServer extends Device

    constructor: ->
        super
        for type, service of services
            @services[type] = new service @
            @emit 'newService', type
        @init()

    type: 'MediaServer'
    version: 1

    addMedia: -> @services.ContentDirectory.addMedia arguments...


module.exports = MediaServer
