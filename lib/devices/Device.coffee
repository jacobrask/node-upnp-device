# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

os  = require 'os'
xml = require 'xml'

config = require '../config'
ssdp   = require '../ssdp'
httpServer = require '../httpServer'

class Device extends (require '../DeviceControlProtocol')

    constructor: (@name, schema) ->
        super schema
        unless @name
            return new Error "Please supply a name for your UPnP Device."
    
    start: (callback) ->
        server = httpServer.createServer @
        server.listen (err, httpServer) =>
            ssdp.announce @, httpServer
            ssdp.listen @, httpServer
            callback err, httpServer

    # build device description element
    buildDescription: (callback) ->
        desc = '<?xml version="1.0" encoding="utf-8"?>'
        desc += xml [
                root: [
                    _attr:
                        xmlns: @makeNS 'device'
                    { specVersion: @buildSpecVersion() }
                    { device: @buildDevice() }
                ]
            ]
        callback null, desc

    # build spec version element
    buildSpecVersion: ->
        [ { major: @schema.upnpVersion.split('.')[0] }
          { minor: @schema.upnpVersion.split('.')[1] } ]

    # build device element
    buildDevice: ->
        [ { deviceType: @makeDeviceType() }
          { friendlyName: "#{@name} @ #{os.hostname()}".substr(0, 64) }
          { manufacturer: 'node-upnp-device' }
          { modelName: @name.substr(0, 32) }
          { UDN: config.uuid }
          { serviceList: @buildServiceList() } ]

    # build an array of all service elements
    buildServiceList: ->
        for serviceType in Object.keys(@services)
            { service: @buildService serviceType }

    # build an array of elements to generate a service XML element
    buildService: (serviceType) ->
        [ { serviceType: @makeServiceType serviceType }
          { serviceId: 'urn:upnp-org:serviceId:' + serviceType }
          { SCPDURL: '/service/description/' + serviceType }
          { controlURL: '/service/control/' + serviceType }
          { eventSubURL: '/service/event/' + serviceType } ]

    makeServerString: ->
        [ "#{os.type()}/#{os.release()}"
          "UPnP/#{@schema.upnpVersion}"
          "#{@name}/1.0"
        ].join ' '

module.exports = Device
