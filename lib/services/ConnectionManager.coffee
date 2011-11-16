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
        @stateVariables =
            'SourceProtocolInfo': @protocols.join(',')
            'SinkProtocolInfo': ''
            'CurrentConnectionIDs': 0

    GetProtocolInfo: (options, callback) ->
        @buildSoapResponse(
            'GetProtocolInfo'
            Source: @protocols.join(','), Sink: ''
            (err, resp) ->
                callback null, resp
        )

    GetCurrentConnectionIDs: (options, callback) ->
        # The optional `PrepareForConnection` action is not implemented,
        # so this should always return `0`.
        @buildSoapResponse(
            'GetCurrentConnectionIDs'
            ConnectionIDs: 0
            (err, resp) ->
                callback null, resp
        )

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
                callback null, resp
        )
    
module.exports = ConnectionManager
