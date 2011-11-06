assert = require 'assert'

http = require 'http'
xml2js = require 'xml2js'
xmlServer = require '../lib/xml-server'
config = require '../lib/config'

testDeviceDescriptions = (deviceType, deviceName, deviceVersion) ->
    xmlServer.listen xmlServer.createServer(deviceType, deviceName), (err, httpServer) ->
        assert.ok !err
        # test device description
        http.get host: httpServer.address, port: httpServer.port, path: '/device/description', (res) ->
            assert.equal res.statusCode, 200
            parser = new xml2js.Parser()
            res.on 'data', (data) ->
                parser.parseString data, (err, result) ->
                    assert.ok !err
                    assert.equal result.device.deviceType, "#{config.schemaPrefix}:device:#{deviceType}:#{deviceVersion}"
                    assert.equal result.device.friendlyName, deviceName

testServiceDescriptions = (deviceType, deviceName, serviceTypes) ->
    xmlServer.listen xmlServer.createServer(deviceType, deviceName), (err, httpServer) ->
        assert.ok !err
        for serviceType in serviceTypes
            http.get host: httpServer.address, port: httpServer.port, path: "/service/description/#{serviceType}", (res) ->
                assert.equal res.statusCode, 200

for deviceType of config.devices
    testDeviceDescriptions deviceType, 'Test Device', config.devices[deviceType].version
    testServiceDescriptions deviceType, 'Test Device', config.devices[deviceType].services
