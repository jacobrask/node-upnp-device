xmlServer = require './lib/xml-server'
ssdpServer = require './lib/ssdp-server'

xmlServer.start ->
    console.log 'xml http server started'
    
ssdpServer.start ->
    console.log 'ssdp udp server started'
