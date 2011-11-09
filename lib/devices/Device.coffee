os  = require 'os'
xml = require 'xml'

config   = require '../config'
ssdp     = require '../ssdp'
UPnPBase = require '../UPnPBase'
web      = require '../web'

class Device extends UPnPBase

    constructor: (@name, schema) ->
        super schema
        unless @name
            return new Error "Please supply a name for your UPnP Device."
        
    start: (callback) ->
        server = web.createServer @
        server.listen (err, httpServer) =>
            ssdp.announce @, httpServer
            ssdp.listen @, httpServer
            callback err, httpServer

    # build device description element
    buildDescription: ->
        console.dir @
        xml [
            root: [
                _attr:
                    xmlns: @_makeNS 'device'
                { specVersion: @_buildSpecVersion() }
                { device: @_buildDevice() }
            ]
        ]

    # build spec version element
    _buildSpecVersion: ->
        [ { major: @schema.upnpVersion.split('.')[0] }
          { minor: @schema.upnpVersion.split('.')[1] } ]

    # build device element
    _buildDevice: ->
        [ { deviceType: @makeDeviceType() }
          { friendlyName: "#{@name} @ #{os.hostname()}".substr(0, 64) }
          { manufacturer: 'node-upnp-device' }
          { modelName: @name.substr(0, 32) }
          { UDN: config.uuid }
          { serviceList: @_buildServiceList() } ]

    # build an array of all service elements
    _buildServiceList: ->
        for serviceType in @services
            { service: @_buildService serviceType }

    # build an array of elements to generate a service XML element
    _buildService: (serviceType) ->
        [ { serviceType: @makeServiceType serviceType }
          { serviceId: 'urn:upnp-org:serviceId:' + serviceType }
          { SCPDURL: '/service/description/' + serviceType }
          { controlURL: '/service/control/' + serviceType }
          { eventSubURL: '/service/event/' + serviceType } ]

    # make service/device type string for ssdp and device description
    _makeType: (category, type) ->
        [ @schema.prefix
          category
          type || @type
          @version
        ].join ':'
    makeDeviceType: -> @_makeType 'device'
    makeServiceType: (type) -> @_makeType 'service', type

module.exports = Device
