xml = require 'xml'

buildSchema = (config, callback) ->
    major = config['version'].split('.')[0]
    minor = config['version'].split('.')[1]
    schema = 'urn:schemas-upnp-org:device-' + major + '-' + minor
    callback xml.Element { _attr: { xmlns: schema } }

buildSpecVersion = (config, callback) ->
    major = config['version'].split('.')[0]
    minor = config['version'].split('.')[1]
    callback xml.Element [ { major: major }, { minor: minor } ]

exports.buildSchema = buildSchema
exports.buildSpecVersion = buildSpecVersion
