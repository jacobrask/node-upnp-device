uuid = require 'node-uuid'
ssdp = require './ssdp'
xmlServer = require './xml-server'

upnp = {}
upnp.createDevice = (options, callback) =>
    @config =
        specs:
            upnp:
                prefix: 'urn:schemas-upnp-org'
                version: '1.0'
        device:
            uuid: 'uuid:' + uuid()
            type: options.device ? 'Basic'
            version: 1
        services: options.services ? [ ]
        network:
            ssdp:
                timeout: 1800
                address: '239.255.255.250'
                port: 1900
            http:
                address: '192.168.9.3'
                port: 3000
        app:
            name: options.app?.name ? 'Generic UPnP Device'
            version: options.app?.version ? '1.0'

    xmlServer.start @config, (err, msg) ->
        callback err, msg

    ssdp.start @config, (err, msg) ->
        callback err, msg

module.exports = upnp
