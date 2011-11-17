# Implements ConnectionManager:1
# http://upnp.org/specs/av/av1/

Service = require './Service'

class ConnectionManager extends Service

    constructor: (@device, type) ->
        super device, type
        @type = 'ConnectionManager'
        @protocols =
            for mimeType in @device.accepts
                "http-get:*:#{mimeType}:*"
        @stateVars =
            'SourceProtocolInfo': @protocols.join(',')
            'SinkProtocolInfo': ''
            'CurrentConnectionIDs': 0

    GetProtocolInfo: (options, callback) ->
        @buildSoapResponse(
            'GetProtocolInfo'
            Source: @protocols.join(','), Sink: ''
            (err, resp) ->
                callback err, resp
        )

    GetCurrentConnectionIDs: (options, callback) ->
        @getStateVar 'CurrentConnectionIDs', 'ConnectionIDs', (err, resp) ->
            callback err, resp

    GetCurrentConnectionInfo: (options, callback) ->
        # `PrepareForConnection` is not implemented, so only `ConnectionID`
        # available is `0`. The following are defaults from specification.
        @buildSoapResponse(
            'GetCurrentConnectionInfo'
            RcsID: -1
            AVTransportID: -1
            ProtocolInfo: @protocols.join(',')
            PeerConnectionManager: ''
            PeerConnectionID: -1
            Direction: 'Output'
            Status: 'OK'
            (err, resp) ->
                callback err, resp
        )

    PrepareForConnection: @optionalAction
    ConnectionComplete: @optionalAction
    
module.exports = ConnectionManager
