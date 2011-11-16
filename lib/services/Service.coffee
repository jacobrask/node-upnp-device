# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

xml2js = require 'xml2js'

protocol = require '../protocol'
uuid     = require 'node-uuid'
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

    event: (type, cbUrl, timeout, callback) ->
        if type is 'subscribe'
            subUuid = "uuid:#{uuid()}"
            @subscriptions[subUuid] = {
                eventKey: 0
                callback: cbUrl
            }
            console.info "Added new subscription with #{subUuid} and callback url #{cbUrl}"
            callback null, { sid: subUuid, timeout: 'Second-1800' }

    buildSoapResponse: xml.buildSoapResponse

module.exports = Service
