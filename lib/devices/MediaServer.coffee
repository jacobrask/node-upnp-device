{Device} = require '../upnp'

class MediaServer extends Device

    constructor: (name, schema) ->
        super name, schema
        @type = 'MediaServer'
        @version = 1
        @services = [ 'ConnectionManager', 'ContentDirectory' ]
        @

    addContentTypes: (newMimeTypes) ->
        if @mimeTypes?
            @mimeTypes = @mimetypes.concat newMimeTypes
        else
            @mimetypes = newMimeTypes
        @

module.exports = MediaServer
