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
                    xmlns: protocol.makeNameSpace()
                { specVersion: buildSpecVersion() }
                { device: buildDevice() }
            ]
        ]
    callback null, desc
