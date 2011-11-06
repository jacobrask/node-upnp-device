assert = require 'assert'

http = require 'http'
xml2js = require 'xml2js'
xmlServer = require '../lib/xml-server'
config = require '../lib/config'
parser = new xml2js.Parser()

testWebServer = (deviceType, deviceName, deviceVersion) ->
    xmlServer.listen xmlServer.createServer(deviceType, deviceName), (err, httpServer) ->
        assert.ok !err
        host = httpServer.address
        port = httpServer.port
        # test device description
        http.get host: host, port: port, path: '/device/description', (res) ->
            assert.equal res.statusCode, 200
            res.on 'data', (data) ->
                parser.parseString data, (err, result) ->
                    assert.ok !err
                    assert.equal result.device.deviceType, "#{config.schemaPrefix}:device:#{deviceType}:#{deviceVersion}"
                    assert.equal result.device.friendlyName, deviceName
                    
for deviceType of config.devices
    testWebServer deviceType, 'Test Device', config.devices[deviceType].version
