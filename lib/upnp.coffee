uuid = require 'node-uuid'
ssdp = require './ssdp'
xmlServer = require './xml-server'

upnp = {}
upnp.createDevice = (type, version, callback) =>
    for arg in arguments
        if typeof arg is 'Function'
            callback = arg

    @config =
        device:
            schema:
                prefix: 'urn:schemas-upnp-org:device'
            uuid: 'uuid:' + uuid()
            type: type ? 'Basic'
            version: version ? '1.0'
        network:
            ssdp:
                timeout: 1800
                address: '239.255.255.250'
                port: 1900
            http:
                address: '192.168.9.3'
                port: 3000
 
    xmlServer.start @config, (err, msg) ->
        callback err, msg

upnp.announce = (name, version, callback) =>
    for arg in arguments
        if typeof arg is 'Function'
            callback = arg

    @config['app'] =
        name: name ? 'Generic UPnP Device'
        version: version ? '1.0'

    ssdp.start @config, (err, msg) ->
        callback err, msg

module.exports = upnp
