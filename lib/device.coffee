xml = require 'xml'

# generate device type string
makeDeviceType = (config) ->
    type = [
        config['upnp']['schema']['prefix']
        config['device']['type']
        config['device']['version']
    ]
    type.join ':'

# build device description element
buildDescription = (device, config, callback) ->

    # generate namespace string
    makeNS = ->
        ns = [
            config['upnp']['schema']['prefix']
            config['upnp']['version'].split('.')[0]
            config['upnp']['version'].split('.')[1]
        ]
        ns.join '-'

    # build spec version element
    buildSpecVersion = ->
        major = config['upnp']['version'].split('.')[0]
        minor = config['upnp']['version'].split('.')[1]
        [
            { major: major }
            { minor: minor }
        ]

    # build device element
    buildDevice = ->
        name = config['app']['name']
        udn = config['device']['uuid']
        [
            { deviceType: makeDeviceType(config) }
            { friendlyName: name }
            { manufacturer: name }
            { modelName: name + ' Media Server' }
            { UDN: udn }
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
