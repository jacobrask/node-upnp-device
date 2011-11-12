# UPnP Device Control Protocol
# http://upnp.org/index.php/sdcps-and-certification/standards/sdcps/

# make namespace string
exports.makeNameSpace = (prefix = 'urn:schemas-upnp-org', version = '1.0') ->
    [ prefix
      'device'
      version.split('.')[0]
      version.split('.')[1]
    ].join '-'

# make service/device type string for ssdp and device description
makeType = (schemaPrefix, category, type, version) ->
    [ schemaPrefix
      category
      type
      version
    ].join ':'

exports.makeDeviceType = (deviceType, version, schemaPrefix = 'urn:schemas-upnp-org') ->
    makeType schemaPrefix, 'device', deviceType, version

exports.makeServiceType = (serviceType, version, schemaPrefix = 'urn:schemas-upnp-org') ->
    makeType schemaPrefix, 'service', serviceType, version
