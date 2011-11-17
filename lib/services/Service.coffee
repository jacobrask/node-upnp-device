# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

makeUuid = require 'node-uuid'
xml2js = require 'xml2js'

httpu    = require '../httpu'
protocol = require '../protocol'
xml      = require '../xml'
{HttpError} = httpu

unless /upnp-device/.test process.env.NODE_DEBUG
    (console[c] = ->) for c in ['log', 'info']

class Service

    constructor: (@device) ->
        @xmlParser = new xml2js.Parser()
        @subscriptions = {}


    # Control action. Most actions build a SOAP response and calls back.
    action: (action, data, callback) ->
        @xmlParser.parseString data, (err, data) =>
            options = data['s:Body']["u:#{action}"]
            @[action] options, (err, data) ->
                callback err, data


    # Event subscriptions.
    subscribe: (cbUrls, reqTimeout, callback) ->
        uuid = "uuid:#{makeUuid()}"
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

    optionalAction: (options, callback) ->
        @buildSoapError(
            code: 602, description: "Optional Action Not Implemented"
            (err, resp) ->
                callback null, resp
        )

    buildSoapResponse: xml.buildSoapResponse
    buildSoapError: xml.buildSoapError
    buildEvent: xml.buildEvent


class Subscription
    constructor: (@uuid, urls, @service) ->
        @eventKey = 0
        @minTimeout = 1800
        @callbackUrls = urls.split(',')
        console.info "Added new subscription #{@uuid} with callbacks", @callbackUrls
        @notify @service.stateVariables

    selfDestruct: (timeout) ->
        # `timeout` is like `Second-(seconds|infinite)`.
        time = /Second-(infinite|\d+)/.exec(timeout)[1]
        if time is 'infinite' or parseInt(time) > @minTimeout
            time = @minTimeout
        else
            time = parseInt(time)
        console.log "Subscription expiring in #{time}s."
        setTimeout(
            => @service.unsubscribe(@uuid)
            time * 1000)
        # Return actual time until unsubscription.
        time

    notify: (vars) ->
        console.info "Sending out event for current state variables to", @callbackUrls
        @service.buildEvent vars, (err, resp) =>
            httpu.postEvent.call(
                @service.device
                @callbackUrls
                @uuid
                @eventKey
                resp
            )
        @eventKey++

module.exports = Service
