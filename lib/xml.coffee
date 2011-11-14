# XML helpers for SOAP and Device descriptions.
# Run with a Device or Service as `@`.

os  = require 'os'
xml = require 'xml'

protocol = require './protocol'

# Build device description XML structure. `@` is bound to Device.
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
        for serviceType in Object.keys(@services)
            { service: buildService serviceType }

    # Build an array of elements contained in a `service` element.
    buildService = (serviceType) =>
        [ { serviceType: protocol.makeServiceType(serviceType, @version) }
          { serviceId: 'urn:upnp-org:serviceId:' + serviceType }
          { SCPDURL: '/service/description/' + serviceType }
          { controlURL: '/service/control/' + serviceType }
          { eventSubURL: '/service/event/' + serviceType } ]

    desc = '<?xml version="1.0" encoding="utf-8"?>'
    desc += xml [
            root: [
                _attr:
                    xmlns: protocol.makeNameSpace()
                { specVersion: buildSpecVersion() }
                { device: buildDevice() }
            ]
        ]
    callback null, desc
