# Implements ConnectionManager:1
# http://upnp.org/specs/av/av1/

Service = require './Service'

class ConnectionManager extends Service

    constructor: (@device, type) ->
        super device, type
        @type = 'ConnectionManager'

    GetProtocolInfo: (options, callback) ->
        protocols =
            for mimeType in @device.accepts
                "http-get:*:#{mimeType}:*"
        @buildSoapResponse(
            'GetProtocolInfo'
            Source: protocols.join(','), Sink: ''
            (err, resp) ->
                callback null, resp
        )

module.exports = ConnectionManager
