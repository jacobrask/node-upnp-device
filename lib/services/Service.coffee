# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

xml    = require 'xml'
xml2js = require 'xml2js'

class Service

    constructor: (@device) ->
        @xmlParser = new xml2js.Parser()

    action: (action, data, callback) ->
        @xmlParser.parseString data, (err, data) =>
            options = data['s:Body']["u:#{action}"]
            @[action] options, (err, data) ->
                callback null, data


    buildSoapResponse: (action, args) ->
        body = {}
        body[action] = [
            _attr:
                'xmlns:u': @makeServiceType @type
        ]
        for arg in args
            body[action].push arg

        res = '<?xml version="1.0"?>'
        res += xml [
            's:Envelope': [
                _attr:
                    'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/'
                    's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/'
                { 's:Body': [ body ] }
            ]
        ]
        return res

module.exports = Service
