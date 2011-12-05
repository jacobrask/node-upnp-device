# XML helpers for SOAP, Device descriptions and DIDL-Lite responses.
# Run with a Device or Service as `@`.

os  = require 'os'
xml = require 'xml'

{ContextError} = require './errors'
httpu    = require './httpu'
protocol = require './protocol'
utils    = require './utils'

xmlDecl = '<?xml version="1.0" encoding="utf-8"?>'

do ->
    # Build `specVersion` element.
    specVersion = (v) -> major: v.split('.')[0], minor: v.split('.')[1]

    # Build an array of `service` elements.
    buildServiceList = (services) ->
        for s of services
            { service: utils.objectToArray buildService.call services[s] }

    # Build `device` element.
    buildDevice = ->
        throw new ContextError if @buildDescription? or @ is global
        deviceType: protocol.makeDeviceType.call @
        friendlyName: "#{@name} @ #{os.hostname()}".substr(0, 64)
        manufacturer: 'UPnP Device for Node.js'
        modelName: @name.substr(0, 32)
        UDN: @uuid
        serviceList: buildServiceList @services

    # Build `service` element.
    buildService = ->
        throw new ContextError if @ is global
        serviceType: protocol.makeServiceType.call @
        serviceId: 'urn:upnp-org:serviceId:' + @type
        SCPDURL: '/service/description/' + @type
        controlURL: '/service/control/' + @type
        eventSubURL: '/service/event/' + @type

    # Build device description XML document. `@` is bound to a Device.
    exports.buildDescription = ->
        xmlDecl + xml [
            root: utils.objectToArray(
                _attr: { xmlns: protocol.makeNS 'device', @schemaPrefix, @schemaVersion }
                specVersion: utils.objectToArray specVersion @upnpVersion
                device: utils.objectToArray buildDevice.call @
            ) ]


# Build a SOAP response XML document. `@` is bound to a Service.
exports.buildSoapResponse = (action, args) ->
    body = {}
    actionKey = "u:#{action}Response"
    # Create an action element.
    body[actionKey] = [ _attr: { 'xmlns:u': protocol.makeServiceType.call @ } ]
    # Add action arguments. First turn each key/value pair into separate
    # objects, to make them separate XML elements.
    body[actionKey] = utils.objectToArray(args, body[actionKey])

    xmlDecl + xml [
        's:Envelope': [
            _attr:
                'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/'
                's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/'
            { 's:Body': [ body ] }
        ]
    ]

# Build a SOAP error XML document. `@` is bound to a Service.
exports.buildSoapError = (error) ->

    xmlDecl + xml [
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
                            _attr: { 'xmlns:e': protocol.makeNS 'control', @device.schemaPrefix, @device.schemaVersion }
                            { errorCode: error.code }
                            { errorDescription: error.message }
                        ]
                    ] }
                ]
            ] }
        ]
    ]


# Build an event notification XML document.
exports.buildEvent = (vars) ->
    xmlDecl + xml [
        'e:propertyset': [
            _attr: { 'xmlns:e': protocol.makeNS 'event', @device.schemaPrefix, @device.schemaVersion }
            { 'e:property': utils.objectToArray vars }
        ]
    ]


# Build a DIDL XML structure for items/containers in the MediaServer device.
exports.buildDidl = (data) ->
    # Build an array of elements contained in an object element.
    buildObject = (obj) =>
        el = []
        el.push {
            _attr:
                id: obj.id
                parentID: obj.parentid
                restricted: 'true'
        }
        el.push 'dc:title': obj.title
        el.push 'upnp:class': obj.class
        if obj.creator
            el.push 'dc:creator': obj.creator
            el.push 'upnp:artist': obj.creator
        if obj.location
            el.push 'res': [
                _attr:
                    protocolInfo: "http-get:*:#{obj.contenttype}:*"
                    size: obj.filesize
                httpu.makeContentUrl.call(@, obj.id) ]
        el

    body = {}
    body['DIDL-Lite'] = []
    body['DIDL-Lite'].push(
        _attr:
            'xmlns': protocol.makeNS 'metadata', @device.schemaPrefix, @device.schemaVersion, '/DIDL-Lite/'
            'xmlns:dc': 'http://purl.org/dc/elements/1.1/'
            'xmlns:upnp': protocol.makeNS 'metadata', @device.schemaPrefix, @device.schemaVersion, '/upnp/'
    )
    for object in data
        type = /object\.(\w+)/.exec(object.class)[1]
        o = {}
        o[type] = buildObject object
        body['DIDL-Lite'].push o

    xml [ body ]
