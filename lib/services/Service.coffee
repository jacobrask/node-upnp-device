# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

xml2js = require 'xml2js'

protocol = require '../protocol'
xml      = require '../xml'

class Service

    constructor: (@device) ->
        @xmlParser = new xml2js.Parser()

    action: (action, data, callback) ->
        @xmlParser.parseString data, (err, data) =>
            options = data['s:Body']["u:#{action}"]
            @[action] options, (err, data) ->
                callback null, data

    buildSoapResponse: xml.buildSoapResponse

module.exports = Service
