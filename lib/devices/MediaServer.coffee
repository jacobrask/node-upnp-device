# Implements MediaServer:1
# http://upnp.org/specs/av/av1/

class MediaServer extends (require './Device')

    constructor: (name, schema) ->
        super name, schema
        @type = 'MediaServer'
        @version = 1
        @

    services:
        ConnectionManager: new (require '../services/ConnectionManager')

module.exports = MediaServer
