{Device} = require '../upnp'

class MediaServer extends Device

    constructor: (name, schema) ->
        super name, schema
        @type = 'MediaServer'
        @version = 1
        @services = [ 'ConnectionManager', 'ContentDirectory' ]
        @

    accept: (mimeTypes) ->
        @mimeTypes = mimeTypes
        @

module.exports = MediaServer
