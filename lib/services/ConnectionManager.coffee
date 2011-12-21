# Implements ConnectionManager:1
# http://upnp.org/specs/av/av1/
#
# vim: ts=2 sw=2 sts=2

"use strict"

Service = require './Service'


class ConnectionManager extends Service

  constructor: (@device) ->
    super
    @stateVars =
      SourceProtocolInfo: { value: '', evented: yes }
      SinkProtocolInfo: { value: '', evented: yes }
      CurrentConnectionIDs: { value: 0,  evented: yes }

    @device.on 'newService', (type) =>
      if type is 'ContentDirectory'
        @device.services.ContentDirectory.on 'newContentType', =>
          # Update protocol info and notify subscribers.
          @stateVars.SourceProtocolInfo.value = @getProtocols()
          @notify()


  # ## Static service properties.
  type: 'ConnectionManager'

  # Optional actions not (yet) implemented.
  optionalActions: [ 'PrepareForConnection', 'ConnectionComplete' ]

  # State variable actions and associated XML element names.
  stateActions:
    GetCurrentConnectionIDs: 'ConnectionIDs'


  # Handle actions coming from `requestHandler`.
  actionHandler: (action, options, cb) ->
    return @optionalAction cb if action in @optionalActions
    return @getStateVar action, stateActions[action], cb if action of @stateActions

    switch action
      when 'GetProtocolInfo'
        @makeProtocolInfo cb
      when 'GetCurrentConnectionInfo'
        @makeConnectionInfo cb
      else
        cb null, @buildSoapError new SoapError 401


  # Build Protocol Info string, `protocol:network:contenttype:additional`.
  getProtocols: ->
    ("http-get:*:#{type}:*" for type in @device.services.ContentDirectory.contentTypes).join(',')


  makeProtocolInfo: (cb) ->
    cb null, @buildSoapResponse 'GetProtocolInfo',
      Source: @stateVars.SourceProtocolInfo.value, Sink: ''


  makeConnectionInfo: (cb) ->
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
