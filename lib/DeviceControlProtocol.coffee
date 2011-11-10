# UPnP Device Control Protocol
# http://upnp.org/index.php/sdcps-and-certification/standards/sdcps/
# inherited by Device and Service

{EventEmitter} = require 'events'

class DeviceControlProtocol extends EventEmitter

    constructor: ->
        @schema =
            prefix: 'urn:schemas-upnp-org'
            version: '1.0'
            upnpVersion: '1.0'

    # make namespace string
    makeNS: (type) ->
        [ @schema.prefix
          type
          @schema.version.split('.')[0]
          @schema.version.split('.')[1]
        ].join '-'

    # make service/device type string for ssdp and device description
    makeType: (category, type) ->
        [ @schema?.prefix || @device.schema.prefix
          category
          type || @type
          @version || @device.version
        ].join ':'

    makeDeviceType: -> @makeType 'device'
    makeServiceType: (type) -> @makeType 'service', type

module.exports = DeviceControlProtocol
