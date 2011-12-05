# Implements ConnectionManager:1
# http://upnp.org/specs/av/av1/

Service = require './Service'

class ConnectionManager extends Service

    constructor: (@device) ->
        super
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

        @device.on 'newService', (type) =>
            if type is 'ContentDirectory'
                @device.services.ContentDirectory.on 'newContentType', =>
                    # Update protocol info and notify subscribers.
                    @stateVars.SourceProtocolInfo.value = @getProtocols()
                    @notify()

    actionHandler: (action, options, callback) ->
        # Optional actions not (yet) implemented.
        optionalActions = [ 'PrepareForConnection', 'ConnectionComplete' ]
        return @optionalAction callback if action in optionalActions

        # State variable actions and associated XML element names.
        stateActions =
            GetCurrentConnectionIDs: 'ConnectionIDs'
        return @getStateVar action, stateActions[action], callback if action of stateActions

        switch action
            when 'GetProtocolInfo'
                @makeProtocolInfo()
            when 'GetCurrentConnectionInfo'
                @makeConnectionInfo()
            else
                callback null, @buildSoapError new SoapError(401)


    # Build Protocol Info string, `protocol:network:contenttype:additional`.
    getProtocols: ->
        ("http-get:*:#{type}:*" for type in @device.services.ContentDirectory.contentTypes).join(',')

    makeProtocolInfo: (options, callback) ->
        callback null, @buildSoapResponse 'GetProtocolInfo',
            Source: @stateVars.SourceProtocolInfo.value, Sink: ''

    makeConnectionInfo: (options, callback) ->
        # `PrepareForConnection` is not implemented, so only `ConnectionID`
        # available is `0`. The following are defaults from specification.
        callback null, @buildSoapResponse 'GetCurrentConnectionInfo',
            RcsID: -1
            AVTransportID: -1
            ProtocolInfo: @protocols.join(',')
            PeerConnectionManager: ''
            PeerConnectionID: -1
            Direction: 'Output'
            Status: 'OK'

module.exports = ConnectionManager
