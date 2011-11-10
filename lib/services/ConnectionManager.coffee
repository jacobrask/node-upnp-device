# Implements ConnectionManager:1
# http://upnp.org/specs/av/av1/

helpers = require '../helpers'

Service = require './Service'

class ConnectionManager extends Service

    constructor: (@device, type) ->
        super device, type
        @type = 'ConnectionManager'

    GetProtocolInfo: (options, callback) ->
        protocols =
            for mimeType in @device.accepts
                "http-get:*:#{mimeType}:*"
        soap = @buildSoapResponse(
            'u:GetProtocolInfoResponse'
            [ { Source: protocols.join(',') }, { Sink: '' } ]
        )
        helpers.debug soap
        callback null, soap

module.exports = ConnectionManager
