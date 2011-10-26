xml = require 'xml'

buildSchema = (version, callback) ->
    major = version.split('.')[0]
    minor = version.split('.')[1]
    schema = 'urn:schemas-upnp-org:device-' + major + '-' + minor
    callback xml.Element { _attr: { xmlns: schema } }

buildSpecVersion = (version, callback) ->
    major = version.split('.')[0]
    minor = version.split('.')[1]
    callback xml.Element [ { major: major }, { minor: minor } ]

exports.buildSchema = buildSchema
exports.buildSpecVersion = buildSpecVersion
