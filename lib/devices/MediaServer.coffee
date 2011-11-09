Device = require './Device'

class MediaServer extends Device

    constructor: (name, schema) ->
        super name, schema
        @type = 'MediaServer'
        @version = 1
        @services = [ 'ConnectionManager', 'ContentDirectory' ]
        @

module.exports = MediaServer
