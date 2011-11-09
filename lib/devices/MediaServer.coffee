# Implements MediaServer:1
# http://upnp.org/specs/av/av1/

Device = require './Device'

class MediaServer extends Device

    constructor: (name, schema) ->
        super name, schema
        @type = 'MediaServer'
        @version = 1
        @services = [ 'ConnectionManager', 'ContentDirectory' ]
        @

module.exports = MediaServer
