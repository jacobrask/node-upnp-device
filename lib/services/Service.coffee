# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

{EventEmitter} = require 'events'
makeUuid = require 'node-uuid'
xml2js   = require 'xml2js'

httpu    = require '../httpu'
protocol = require '../protocol'
xml      = require '../xml'
{HttpError} = httpu

class Service extends EventEmitter

    constructor: (@device) ->

    # Control action. Most actions build a SOAP response and calls back.
    action: (action, data, callback) ->
        xmlParser = new xml2js.Parser()
        xmlParser.parseString data, (err, data) =>
            options = data['s:Body']["u:#{action}"]
            @[action] options, callback

    # Event subscriptions.
    subscribe: (cbUrls, reqTimeout, callback) ->
        uuid = "uuid:#{makeUuid()}"
        @subscriptions ?= {}
        @subscriptions[uuid] = new Subscription(
            uuid
            cbUrls
            @
        )
        realTimeout = @subscriptions[uuid].selfDestruct reqTimeout
        callback null, sid: uuid, timeout: "Second-#{realTimeout}"

    renew: (uuid, reqTimeout, callback) ->
        unless @subscriptions[uuid]?
            console.info "Got subscription renewal request but could not find device #{sid}."
            return callback new HttpError 412
        console.info "Renewing subscription #{uuid}."
        realTimeout = @subscriptions[uuid].selfDestruct reqTimeout
        callback null, sid: uuid, timeout: "Second-#{realTimeout}"

    unsubscribe: (uuid) ->
        console.info "Deleting subscription #{uuid}."
        delete @subscriptions[uuid]

    # For optional actions not (yet) implemented.
    optionalAction: (options, callback) ->
        @buildSoapError(new SoapError(602), callback)

    # Several Service actions only serve to return a State Variable.
    getStateVar: (varName, elName, callback) ->
        o = {}
        o[elName] = @stateVars[varName].value
        @buildSoapResponse(
            "Get#{varName}"
            o
            callback
        )

    # Notify all subscribers of updated state variables.
    notify: ->
        for uuid, sub of @subscriptions
            @subscriptions[uuid].notify()

    buildSoapResponse: xml.buildSoapResponse
    buildSoapError: xml.buildSoapError
    buildEvent: xml.buildEvent
    buildDidl: xml.buildDidl


class Subscription
    constructor: (@uuid, urls, @service) ->
        @eventKey = 0
        @minTimeout = 1800
        @callbackUrls = urls.split(',')
        console.info "Added new subscription for #{@service.type} with #{@uuid}."
        @notify()

    selfDestruct: (timeout) ->
        clearTimeout(@destructionTimer) if @destructionTimer?
        # `timeout` is like `Second-(seconds|infinite)`.
        time = /Second-(infinite|\d+)/.exec(timeout)[1]
        if time is 'infinite' or parseInt(time) > @minTimeout
            time = @minTimeout
        else
            time = parseInt(time)
        console.log "Subscription #{@uuid} expiring in #{time}s."
        @destructionTimer = setTimeout(
            => @service.unsubscribe(@uuid)
            time * 1000)
        # Return actual time until unsubscription.
        time

    notify: ->
        # Specification states that all variables are sent out to all clients
        # even if only one variable changed.
        console.info "Sending out event for current state variables to", @callbackUrls
        eventedVars = {}
        for key, val of @service.stateVars when val.evented
            eventedVars[key] = val.value
        @service.buildEvent eventedVars, (err, resp) =>
            httpu.postEvent.call(
                @service.device
                @callbackUrls
                @uuid
                @eventKey
                resp
            )
        @eventKey++

module.exports = Service
