# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

xml    = require 'xml'
xml2js = require 'xml2js'

class Service extends (require '../DeviceControlProtocol')

    constructor: (@type) ->
        @xmlParser = new xml2js.Parser()

    action: (action, data) ->
        parser.parseString data, (err, data) ->
            @[action](data['s:Body']["u:#{actionName}"])

module.exports = Service

###
makeActionResponse = exports.makeActionResponse = (serviceType, action) ->
    xml [
        's:Envelope': [
            _attr:
                'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/'
                's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/'
            { 's:Body': [ { foo: 'bar' } ] }
        ]
    ]
###
