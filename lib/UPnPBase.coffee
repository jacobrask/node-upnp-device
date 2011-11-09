# shared between Device and Service

class UPnP
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

module.exports = UPnP
