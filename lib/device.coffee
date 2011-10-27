extend = require('./helpers').extend
xml = require 'xml'

# merged with configs passed when loading module
configDefaults =
    device:
        schema:
            prefix: 'urn:schemas-upnp-org:device'
    uuid: '4061a4c0-0020-11e1-be50-0800200c9a66'

exports.buildDescription = (response, config, callback) ->
    extend config, configDefaults

    # generate namespace string
    genNS = ->
        ns = [
            config['device']['schema']['prefix']
            config['device']['version'].split('.')[0]
            config['device']['version'].split('.')[1]
        ]
        ns.join '-'

    # generate device type string
    genDeviceType = ->
        type = [
            config['device']['schema']['prefix']
            config['device']['type']
            config['device']['version'].split('.')[0]
        ]
        type.join ':'

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
            { deviceType: genDeviceType() }
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
        callback()
