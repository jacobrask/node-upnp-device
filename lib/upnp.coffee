uuid = require 'node-uuid'
xmlServer = require './xml-server'
ssdpServer = require './ssdp-server'
device = require './device'
extend = require('./helpers').extend

configDefaults =
    device:
        schema:
            prefix: 'urn:schemas-upnp-org:device'
    network:
        ssdp:
            timeout: 1800
            address: '239.255.255.250'
            port: 1900
    uuid: uuid()

upnp = {}
upnp.start = (config, callback) ->
    extend config, configDefaults

    xmlServer.start config, ->
        console.log 'xml server started'
        callback null
        ssdpServer.send 'NOTIFY', config, ->
            console.log 'ssdp server started'
            callback null

module.exports = upnp
