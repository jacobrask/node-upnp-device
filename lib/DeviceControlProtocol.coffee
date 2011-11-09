# UPnP Device Control Protocol
# http://upnp.org/index.php/sdcps-and-certification/standards/sdcps/
# inherited by Device and Service

class DeviceControlProtocol extends (require 'events'.EventEmitter)

    constructor: ->
        @schema =
            prefix: 'urn:schemas-upnp-org'
            version: '1.0'
            upnpVersion: '1.0'

    # make namespace string
    _makeNS: (type) ->
        [ @schema.prefix
          type
          @schema.version.split('.')[0]
          @schema.version.split('.')[1]
        ].join '-'

module.exports = DeviceControlProtocol
