xml = require 'xml'

config =
    upnp_urn: 'urn:schemas-upnp-org'
    version: '1.0'
    type: 'MediaServer'
    uuid: '4061a4c0-0020-11e1-be50-0800200c9a66'
    app:
        name: 'Bragi'
        version: '0.0.1'
        url: 'http://'

buildNSURN = (config, callback) ->
    major = config['version'].split('.')[0]
    minor = config['version'].split('.')[1]
    ns = config['upnp_urn'] + ':device-'
    ns += major + '-' + minor
    callback ns

buildSpecVersion = (config, callback) ->
    major = config['version'].split('.')[0]
    minor = config['version'].split('.')[1]
    specVersion = []
    specVersion.push { major: major }
    specVersion.push { minor: minor }
    callback specVersion

buildDevice = (config, callback) ->
    type = config['upnp_urn'] + ':device:'
    type += config['type'] + ':'
    type += config['version'].split('.')[0]
    name = config['app']['name']
    url = config['app']['url']
    version = config['app']['version']
    udn = 'uuid:' + config['uuid']
    d = []
    d.push { deviceType: type }
    d.push { friendlyName: name }
    d.push { manufacturer: name }
    d.push { modelName: name + ' Media Server' }
    d.push { UDN: udn }
    callback d

exports.buildDescription = (response, callback) ->
    # get device schema / xml namespace
    buildNSURN config, (xmlns) ->
        root = xml.Element { _attr: { xmlns: xmlns } }
        desc = xml { root: root }, { stream: true }
        desc.pipe response

        process.nextTick ->
            buildSpecVersion config, (specVersionXML) ->
                root.push { specVersion: specVersionXML }
                buildDevice config, (deviceXML) ->
                    root.push { device: deviceXML }
                    root.close()
                    callback()
