# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

makeUuid = require 'node-uuid'
xml2js = require 'xml2js'

httpu    = require '../httpu'
protocol = require '../protocol'
xml      = require '../xml'

class Service

    constructor: (@device) ->
        @xmlParser = new xml2js.Parser()
        @subscriptions = {}

    action: (action, data, callback) ->
        @xmlParser.parseString data, (err, data) =>
            options = data['s:Body']["u:#{action}"]
            @[action] options, (err, data) ->
                callback null, data

    subscribe: (cbUrls, timeout, callback) ->
        uuid = "uuid:#{makeUuid()}"
        @subscriptions[uuid] = new Subscription(
            cbUrls
            timeout
            uuid
            @
        )
        callback null, { sid: uuid, timeout: 'Second-1800' }

    renew: (uuid, timeout, callback) ->
        unless @subscriptions[uuid]?
            console.info "Got subscription renewal request but could not find
 device #{sid}."
            return callback new HttpError 412
        console.info "Renewed subscription #{uuid}"
        @subscriptions[uuid].selfDestruct(timeout)

    unsubscribe: (uuid) ->
        delete @subscriptions[uuid]

    buildSoapResponse: xml.buildSoapResponse


class Subscription
    constructor: (urls, timeout, @uuid, @service) ->
        @eventKey = 0
        @callbackUrls = urls.split(',')
        console.info "Added new subscription #{@uuid} and callback url", @callbackUrls
        @selfDestruct timeout
        # Send out event on current state variables.
        @notify @service.stateVariables

    selfDestruct: (timeout) ->
        # Self destruct in `ms` milliseconds.
        ms = parseInt(/Second-(\d+)/.exec(timeout)[1]) * 1000
        setTimeout(
            =>
                console.info "Subscription #{@uuid} has timed out, deleting."
                @service.unsubscribe @uuid
            ms)

    notify: (vars) ->
        xml.buildEvent vars, (err, resp) =>
            httpu.postEvent.call(
                @service.device
                @callbackUrls
                @uuid
                @eventKey
                resp
            )
        @eventKey++

module.exports = Service
