xml = require 'xml'
config = require './config'

# build device description element
buildDescription = exports.buildDescription = (deviceType, deviceName) ->
    xml [
        root: [
            _attr:
                xmlns: makeNS('device')
            { specVersion: buildSpecVersion() }
            { device: buildDevice(deviceType, deviceName) }
        ]
    ]

# make namespace string
makeNS = (category) ->
    [ config.schemaPrefix
      category
      config.versions.schema.split('.')[0]
      config.versions.schema.split('.')[1]
    ].join '-'

# build spec version element
buildSpecVersion = ->
    [ { major: config.versions.upnp.split('.')[0] }
      { minor: config.versions.upnp.split('.')[1] } ]

# build device element
buildDevice = (deviceType, deviceName) ->
    name = deviceName.substr(0, 64)
    [ { deviceType: makeDeviceType deviceType }
      { friendlyName: name }
      { manufacturer: name }
      { modelName: name.substr(0, 32) }
      { UDN: config.uuid }
      { serviceList: buildServiceList deviceType } ]

# make service/device type string for SSDP and Device Description
makeType = (category, type, version) ->
    [ config.schemaPrefix
      category
      type
      version
    ].join ':'

makeDeviceType = exports.makeDeviceType = (type) ->
    makeType('device', type, config.devices[type].version)

makeServiceType = exports.makeServiceType = (type) ->
    # get service's parent device type version
    for deviceType, props of config.devices
        version = props.version if type in props.services
    makeType('service', type, version)

# build an array of all service elements
buildServiceList = (deviceType) ->
    services = []
    for serviceType in config.devices[deviceType].services
        services.push { service: buildService serviceType }
    services

# build an array of elements to generate a service XML element
buildService = (serviceType) ->
    [ { serviceType: makeServiceType serviceType }
      { serviceId: 'urn:upnp-org:serviceId:' + serviceType }
      { SCPDURL: '/service/description/' + serviceType }
      { controlURL: '/service/control/' + serviceType }
      { eventSubURL: '/service/event/' + serviceType } ]
