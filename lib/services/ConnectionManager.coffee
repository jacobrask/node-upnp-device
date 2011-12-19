# Implements ConnectionManager:1
# http://upnp.org/specs/av/av1/
#
# vim: ts=2 sw=2 sts=2

"use strict"

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

  actionHandler: (action, options, cb) ->
    # Optional actions not (yet) implemented.
    optionalActions = [ 'PrepareForConnection', 'ConnectionComplete' ]
    return @optionalAction cb if action in optionalActions

    # State variable actions and associated XML element names.
    stateActions = GetCurrentConnectionIDs: 'ConnectionIDs'
    return @getStateVar action, stateActions[action], cb if action of stateActions

    switch action
      when 'GetProtocolInfo'
        @makeProtocolInfo()
      when 'GetCurrentConnectionInfo'
        @makeConnectionInfo()
      else
        cb null, @buildSoapError new SoapError(401)


  # Build Protocol Info string, `protocol:network:contenttype:additional`.
  getProtocols: ->
    ("http-get:*:#{type}:*" for type in @device.services.ContentDirectory.contentTypes).join(',')

  makeProtocolInfo: (options, cb) ->
    cb null, @buildSoapResponse 'GetProtocolInfo',
      Source: @stateVars.SourceProtocolInfo.value, Sink: ''

  makeConnectionInfo: (options, cb) ->
    # `PrepareForConnection` is not implemented, so only `ConnectionID`
    # available is `0`. The following are defaults from specification.
    cb null, @buildSoapResponse 'GetCurrentConnectionInfo',
      RcsID: -1
      AVTransportID: -1
      ProtocolInfo: @protocols.join(',')
      PeerConnectionManager: ''
      PeerConnectionID: -1
      Direction: 'Output'
      Status: 'OK'

module.exports = ConnectionManager
