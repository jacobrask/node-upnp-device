# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

fs   = require 'fs'
os   = require 'os'
uuid = require 'node-uuid'
xml  = require 'xml'

protocol = require '../protocol'
ssdp = require '../ssdp'
httpServer = require '../httpServer'

class Device

    constructor: (@name) ->
        @schema =
            prefix: 'urn:schemas-upnp-org'
            version: '1.0'
            upnpVersion: '1.0'
        @name ?= "Generic #{@type} device"
        @setUUID()

    start: (callback) ->
        @httpServer = httpServer.createServer @
        @httpServer.listen (err, serverInfo) =>
            @httpServerAddress = serverInfo.address
            @httpServerPort = serverInfo.port

            @ssdp = ssdp.create @
            @ssdp.announce()
            callback null, ':-)'

    setUUID: ->
        # try to persist UUID across restarts, storing as JSON in upnp-uuid file
        try
            data = fs.readFileSync("#{__dirname}/../../upnp-uuid", 'utf8')
            data = JSON.parse data
        catch error
            data = {}
            data[@type] = {}

        if data[@type][@name]
            @uuid = data[@type][@name]
        else
            @uuid = 'uuid:' + uuid()
            data[@type] ?= {}
            data[@type][@name] = @uuid
        fs.writeFileSync("#{__dirname}/../../upnp-uuid", JSON.stringify(data))


    # build device description element
    buildDescription: (callback) ->
        desc = '<?xml version="1.0" encoding="utf-8"?>'
        desc += xml [
                root: [
                    _attr:
                        xmlns: protocol.makeNameSpace()
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
        [ { deviceType: protocol.makeDeviceType(@type, @version) }
          { friendlyName: "#{@name} @ #{os.hostname()}".substr(0, 64) }
          { manufacturer: 'node-upnp-device' }
          { modelName: @name.substr(0, 32) }
          { UDN: @uuid }
          { serviceList: @buildServiceList() } ]

    # build an array of all service elements
    buildServiceList: ->
        for serviceType in Object.keys(@services)
            { service: @buildService serviceType }

    # build an array of elements to generate a service XML element
    buildService: (serviceType) ->
        [ { serviceType: protocol.makeServiceType(serviceType, @version) }
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
