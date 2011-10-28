uuid = require 'node-uuid'
ssdp = require './ssdp'
extend = require('./helpers').extend

configDefaults =
    device:
        schema:
            prefix: 'urn:schemas-upnp-org:device'
        uuid: 'uuid:' + uuid()
    network:
        ssdp:
            timeout: 1800
            address: '239.255.255.250'
            port: 1900

upnp = {}
upnp.start = (config, callback) ->
    # add config values recieved from caller
    extend config, configDefaults
    ssdp.start config, (err, msg) ->
        callback err, msg

module.exports = upnp
