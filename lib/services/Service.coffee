# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

xml2js = require 'xml2js'

protocol = require '../protocol'
makeUuid = require 'node-uuid'
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
        console.log "Current subscriptions:", @subscriptions
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
        console.log "Current subscriptions:", @subscriptions

    buildSoapResponse: xml.buildSoapResponse

class Subscription
    constructor: (urls, timeout, @uuid, @parent) ->
        eventKey: 0
        @callbackUrls = urls.split(',')
        console.info "Added new subscription #{@uuid} and callback url", @callbackUrls
        @selfDestruct(timeout)

    selfDestruct: (timeout) ->
        # Self destruct in `ms` milliseconds.
        ms = parseInt(/Second-(\d+)/.exec(timeout)[1]) * 1000
        setTimeout(
            =>
                console.info "Subscription #{@uuid} has timed out, deleting."
                @parent.unsubscribe(@uuid)
            ms)

module.exports = Service
