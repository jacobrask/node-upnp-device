{Device} = require '../upnp'

class MediaServer extends Device

    constructor: (@name) ->
        @type = 'MediaServer'

    accept: (mimeTypes) ->
        @mimeTypes = mimeTypes

module.exports = MediaServer
