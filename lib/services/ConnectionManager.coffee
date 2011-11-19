# Implements ConnectionManager:1
# http://upnp.org/specs/av/av1/

Service = require './Service'

class ConnectionManager extends Service

    constructor: (@device, type) ->
        super device, type
        @type = 'ConnectionManager'
        @stateVars =
            SourceProtocolInfo:
                value: ''
                evented: true
            SinkProtocolInfo:
                value: ''
                evented: true
            CurrentConnectionIDs:
                value: 0
                evented: true

        @device.services.ContentDirectory.on 'newContentType', =>
            # Update protocol info and notify subscribers.
            @stateVars.SourceProtocolInfo.value = @getProtocols()
            @notify()

    # Build Protocol Info string, `protocol:network:contenttype:additional`.
    getProtocols: ->
        ("http-get:*:#{type}:*" for type in @device.services.ContentDirectory.contentTypes).join(',')

    GetProtocolInfo: (options, callback) ->
        @buildSoapResponse(
            'GetProtocolInfo'
            Source: @stateVars.SourceProtocolInfo.value, Sink: ''
            callback
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
            callback
        )

    GetCurrentConnectionIDs: (options, callback) ->
        @getStateVar 'CurrentConnectionIDs', 'ConnectionIDs', callback

    PrepareForConnection: @optionalAction
    ConnectionComplete: @optionalAction
    
module.exports = ConnectionManager
