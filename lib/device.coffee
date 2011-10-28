xml = require 'xml'

# generate device type string
makeDeviceType = (config) ->
    type = [
        config['device']['schema']['prefix']
        config['device']['type']
        config['device']['version'].split('.')[0]
    ]
    type.join ':'

# build device description element
buildDescription = (response, config, callback) ->

    # generate namespace string
    genNS = ->
        ns = [
            config['device']['schema']['prefix']
            config['device']['version'].split('.')[0]
            config['device']['version'].split('.')[1]
        ]
        ns.join '-'

    # build spec version element
    buildSpecVersion = ->
        major = config['device']['version'].split('.')[0]
        minor = config['device']['version'].split('.')[1]
        [
            { major: major }
            { minor: minor }
        ]

    # build device element
    buildDevice = ->
        name = config['app']['name']
        url = config['app']['url']
        version = config['app']['version']
        udn = 'uuid:' + config['uuid']
        [
            { deviceType: genDeviceType(config) }
            { friendlyName: name }
            { manufacturer: name }
            { modelName: name + ' Media Server' }
            { UDN: udn }
        ]

    root = xml.Element { _attr: { xmlns: genNS() } }
    desc = xml { root: root }, { stream: true }
    desc.pipe response

    process.nextTick ->
        root.push { specVersion: buildSpecVersion() }
        root.push { device: buildDevice() }
        root.close()
        callback null

exports.buildDescription = buildDescription
exports.makeDeviceType = makeDeviceType
