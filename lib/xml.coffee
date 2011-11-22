# XML helpers for SOAP, Device descriptions and DIDL-Lite responses.
# Run with a Device or Service as `@`.

os  = require 'os'
xml = require 'xml'

helpers = require './helpers'
protocol = require './protocol'

# Build device description XML document. `@` is bound to a Device.
exports.buildDescription = (callback) ->

    # Build `specVersion` element.
    buildSpecVersion = =>
        [ { major: @upnpVersion.split('.')[0] }
          { minor: @upnpVersion.split('.')[1] } ]

    # Build `device` element.
    buildDevice = =>
        [ { deviceType: protocol.makeDeviceType.call @ }
          { friendlyName: "#{@name} @ #{os.hostname()}".substr(0, 64) }
          { manufacturer: 'UPnP Device for Node.js' }
          { modelName: @name.substr(0, 32) }
          { UDN: @uuid }
          { serviceList: buildServiceList() } ]

    # Build an array of all `service` elements.
    buildServiceList = =>
        for s of @services
            { service: buildService.call @services[s] }

    # Build an array of elements contained in a `service` element.
    buildService = ->
        [ { serviceType: protocol.makeServiceType.call(@) }
          { serviceId: 'urn:upnp-org:serviceId:' + @type }
          { SCPDURL: '/service/description/' + @type }
          { controlURL: '/service/control/' + @type }
          { eventSubURL: '/service/event/' + @type } ]

    desc = '<?xml version="1.0" encoding="utf-8"?>'
    desc += xml [
            root: [
                _attr:
                    xmlns: protocol.makeNameSpace.call(@, 'device')
                { specVersion: buildSpecVersion() }
                { device: buildDevice() }
            ]
        ]
    callback null, desc


# Build a SOAP response XML document. `@` is bound to a Service.
exports.buildSoapResponse = (action, args, callback) ->
    body = {}
    actionKey = "u:#{action}Response"
    # Create an action element.
    body[actionKey] = [ _attr: { 'xmlns:u': protocol.makeServiceType.call @ } ]
    # Add action arguments. First turn each key/value pair into separate
    # objects, to make them separate XML elements.
    body[actionKey] = helpers.objToArr(args, body[actionKey])

    resp = '<?xml version="1.0" encoding="utf-8"?>'
    resp += xml [
        's:Envelope': [
            _attr:
                'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/'
                's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/'
            { 's:Body': [ body ] }
        ]
    ]
    callback null, resp

# Build a SOAP error XML document. `@` is bound to a Service.
exports.buildSoapError = (error, callback) ->

    resp = '<?xml version="1.0" encoding="utf-8"?>'
    resp += xml [
        's:Envelope': [
            _attr:
                'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/'
                's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/'
            { 's:Body': [
                's:Fault': [
                    { faultcode: 's:Client' }
                    { faultstring: 'UPnPError' }
                    { detail: [
                        'UPnPError': [
                            _attr: { 'xmlns:e': protocol.makeNameSpace.call(@, 'control') }
                            { errorCode: error.code }
                            { errorDescription: error.message }
                        ]
                    ] }
                ]
            ] }
        ]
    ]
    callback null, resp


# Build an event notification XML document.
exports.buildEvent = (vars, callback) ->
    resp = '<?xml version="1.0" encoding="utf-8"?>'
    resp += xml [
        'e:propertyset': [
            _attr:
                'xmlns:e': protocol.makeNameSpace.call(@, 'event')
            { 'e:property': helpers.objToArr(vars) }
        ]
    ]
    callback null, resp


exports.buildDidl = (data) ->

    # Build an array of elements contained in an object element.
    buildObject = (obj) ->
        el = []
        el.push {
            _attr:
                id: obj.id
                parentID: obj.parentid
                restricted: 'false'
        }
        el.push 'upnp:class': obj.class
        el.push 'dc:title': obj.title
        if obj.creator
            el.push 'dc:creator': obj.creator
        if obj.location
            el.push 'res': [
                _attr:
                    protocolInfo: obj.protocol
                    size: obj.filesize
                obj.location ]
        el

    body = {}
    body['DIDL-Lite'] = []
    body['DIDL-Lite'].push(
        _attr:
            'xmlns': protocol.makeNameSpace.call(@, 'metadata') + '/DIDL-Lite/'
            'xmlns:dc': 'http://purl.org/dc/elements/1.1/'
            'xmlns:upnp': protocol.makeNameSpace.call(@, 'metadata') + '/upnp/'
    )
    for object in data
        type = /object\.(\w+)/.exec(object.class)[1]
        o = {}
        o[type] = buildObject object
        body['DIDL-Lite'].push o

    xml [ body ]


# Create an error object out of predefined UPnP SOAP
# error code-message combinations.
class SoapError extends Error
    constructor: (@code) ->
        STATUS_CODES =
            401: "Invalid Action"
            402: "Invalid Args"
            501: "Action Failed"
            600: "Argument Value Invalid"
            601: "Argument Value Out of Range"
            602: "Optional Action Not Implemented"
            604: "Human Intervention Required"
            701: "No Such Object"
            709: "Invalid Sort Criteria"
        @message = STATUS_CODES[@code]
exports.SoapError = SoapError
