# Implements MediaServer:1
# http://upnp.org/specs/av/av1/

services =
    ConnectionManager: require '../services/ConnectionManager'

class MediaServer extends (require './Device')

    constructor: (name, schema) ->
        @type = 'MediaServer'
        @version = 1
        @accepts = [ 'text/plain' ]
        @services = do =>
            obj = {}
            for name, service of services
                obj[name] = new services[name](@)
            return obj
        super name, schema

module.exports = MediaServer
