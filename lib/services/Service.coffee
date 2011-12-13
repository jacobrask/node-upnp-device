# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

"use strict"

{EventEmitter} = require 'events'
log = new (require 'log')
makeUuid = require 'node-uuid'
{Parser:XmlParser} = require 'xml2js'

{SoapError} = require '../errors'
protocol = require '../protocol'
xml = require '../xml'

class Service extends EventEmitter

    constructor: (@device) ->

    # Control action. Most actions build a SOAP response and calls back.
    action: (action, data, callback) ->
        (new XmlParser).parseString data, (err, data) =>
            @actionHandler action, data['s:Body']["u:#{action}"], callback

    # Event subscriptions.
    subscribe: (cbUrls, reqTimeout) ->
        uuid = "uuid:#{makeUuid()}"
        (@subs?={})[uuid] = new Subscription uuid, cbUrls, @
        timeout = @subs[uuid].selfDestruct reqTimeout
        log.debug "Added new subscription for #{@type} with #{uuid}, expiring in #{timeout}s."
        sid: uuid, timeout: "Second-#{timeout}"

    renew: (uuid, reqTimeout) ->
        unless @subs[uuid]?
            log.warning "Got subscription renewal request but could not find device #{sid}."
            return null
        timeout = @subs[uuid].selfDestruct reqTimeout
        log.debug "Renewing subscription #{uuid}, expiring in #{timeout}s."
        sid: uuid, timeout: "Second-#{timeout}"

    unsubscribe: (uuid) ->
        log.debug "Deleting subscription #{uuid}."
        delete @subs[uuid] if @subs[uuid]?

    # For optional actions not (yet) implemented.
    optionalAction: (callback) -> callback null, @buildSoapError new SoapError(602)

    # Service actions that only return a State Variable.
    getStateVar: (action, elName, callback) ->
        # Actions start with 'Get' followed by variable name.
        varName = /^(Get)?(\w+)$/.exec(action)[2]
        unless varName of @stateVars
            return @buildSoapError new SoapError(404)
        (el={})[elName] = @stateVars[varName].value
        callback null, @buildSoapResponse action, el

    # Notify all subscribers of updated state variables.
    notify: -> do @subs[uuid].notify for uuid of @subs

    buildSoapResponse: -> xml.buildSoapResponse.call @device, arguments...
    buildSoapError: -> xml.buildSoapError.call @device, arguments...
    buildEvent: -> xml.buildEvent.call @device, arguments...
    buildDidl: -> xml.buildDidl.call @device, arguments...


class Subscription
    constructor: (@uuid, urls, @service) ->
        @eventKey = 0
        @minTimeout = 1800
        @callbackUrls = urls.split ','
        @notify()

    selfDestruct: (timeout) ->
        clearTimeout(@destructionTimer) if @destructionTimer?
        # `timeout` is like `Second-(seconds|infinite)`.
        time = /Second-(infinite|\d+)/.exec(timeout)[1]
        if time is 'infinite' or parseInt(time) > @minTimeout
            time = @minTimeout
        else
            time = parseInt(time)
        @destructionTimer = setTimeout(
            => @service.unsubscribe @uuid
            time * 1000)
        # Return actual time until unsubscription.
        time

    notify: ->
        # Specification states that all variables are sent out to all clients
        # even if only one variable changed.
        log.debug "Sending out event for current state variables to #{@callbackUrls}"
        eventedVars = {}
        for key, val of @service.stateVars when val.evented
            eventedVars[key] = val.value
        eventXML = @service.buildEvent eventedVars
        protocol.postEvent.call @service.device, @callbackUrls, @uuid, @eventKey, eventXML
        @eventKey++

module.exports = Service
