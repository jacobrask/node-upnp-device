xmlServer = require './xml-server'
ssdpServer = require './ssdp-server'
device = require './device'

upnp = {}
upnp.start = ->
    xmlServer.start ->
        console.log 'xml server started'

module.exports = upnp
