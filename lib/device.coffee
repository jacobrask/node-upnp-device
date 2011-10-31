xml = require 'xml'

# generate device type string
makeDeviceType = (config) ->
    type = [
        config.specs.upnp.prefix
        'device'
        config.device.type
        config.device.version
    ]
    type.join ':'

# build device description element
buildDescription = (config, callback) ->

    # generate namespace string
    makeNS = ->
        ns = [
            config.specs.upnp.prefix
            'device'
            config.specs.upnp.version.split('.')[0]
            config.specs.upnp.version.split('.')[1]
        ]
        ns.join '-'

    # build spec version element
    buildSpecVersion = ->
        major = config.specs.upnp.version.split('.')[0]
        minor = config.specs.upnp.version.split('.')[1]
        [
            { major: major }
            { minor: minor }
        ]

    # build device element
    buildDevice = ->
        name = config.app.name.substr(0, 64)
        [
            { deviceType: makeDeviceType(config) }
            { friendlyName: name }
            { manufacturer: name }
            { modelName: name.substr(0, 32) }
            { UDN: config.device.uuid }
        ]

    xml [
        root: [
            _attr:
                xmlns: makeNS()
            { specVersion: buildSpecVersion() }
            { device: buildDevice() }
        ]
    ]

exports.buildDescription = buildDescription
exports.makeDeviceType = makeDeviceType
