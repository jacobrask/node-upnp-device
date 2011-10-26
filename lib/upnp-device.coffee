xml = require 'xml'

buildNSURN = (config, callback) ->
    major = config['version'].split('.')[0]
    minor = config['version'].split('.')[1]
    ns = config['upnp_urn'] + ':device-'
    ns += major + '-' + minor
    callback xml.Element { _attr: { xmlns: ns } }

buildSpecVersion = (config, callback) ->
    major = config['version'].split('.')[0]
    minor = config['version'].split('.')[1]
    callback xml.Element [ { major: major }, { minor: minor } ]

buildDevice = (config, callback) ->
    type = config['upnp_urn'] + ':device:'
    type += config['type'] + ':'
    type += config['version'].split('.')[0]
    callback type

exports.buildNSURN = buildNSURN
exports.buildSpecVersion = buildSpecVersion
exports.buildDevice = buildDevice
