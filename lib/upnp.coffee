xmlServer = require './xml-server'
ssdpServer = require './ssdp-server'
device = require './device'

upnp = {}
upnp.start = (config, callback) ->
    xmlServer.start config, ->
        console.log 'xml server started'
        callback()

module.exports = upnp
