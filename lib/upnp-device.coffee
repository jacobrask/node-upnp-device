xml = require 'xml'

exports.buildNSURN = (config, callback) ->
    major = config['version'].split('.')[0]
    minor = config['version'].split('.')[1]
    ns = config['upnp_urn'] + ':device-'
    ns += major + '-' + minor
    callback ns

exports.buildSpecVersion = (config, callback) ->
    major = config['version'].split('.')[0]
    minor = config['version'].split('.')[1]
    specVersion = []
    specVersion.push { major: major }
    specVersion.push { minor: minor }
    callback specVersion

exports.buildDevice = (config, callback) ->
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

