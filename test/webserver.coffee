assert = require 'assert'

http = require 'http'
xml2js = require 'xml2js'
xmlServer = require '../lib/xml-server'
parser = new xml2js.Parser()

deviceType = 'MediaServer'
deviceName = 'Test Device'
server = xmlServer.createServer deviceType, deviceName
xmlServer.listen server, (err, httpServer) ->
    host = httpServer.address
    port = httpServer.port
    # test device description
    http.get host: host, port: port, path: '/device/description', (res) ->
        assert.equal res.statusCode, 200
        res.on 'data', (data) ->
            parser.parseString data, (err, result) ->
                assert.equal result.device.deviceType, 'urn:schemas-upnp-org:device:' + deviceType + ':1'
                assert.equal result.device.friendlyName, deviceName
