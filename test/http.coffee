# vim: ts=2 sw=2 sts=2

assert = require 'assert'
http = require 'http'
upnp = require '../index'
_ = require '../lib/utils'
{ Parser: XmlParser } = require 'xml2js'

exports['Start an HTTP server'] = (test) ->
  deviceName = 'Foo'
  device = upnp.createDevice 'MediaServer', deviceName
  device.on 'ready', ->
    test.ok _.isString(device.address), "@address should be a string"
    test.ok _.isNumber(device.httpPort), '@httpPort should be a number'
    req = http.get host: device.address, port: device.httpPort, path: '/device/description', (res) ->
      test.equal res.statusCode, 200
      data = ''
      res.on 'data', (chunk) -> data += chunk
      res.on 'close', (err) -> test.ifError err, "Server error - #{err.message}"
      res.on 'end', -> (new XmlParser).parseString data, (err, data) ->
        test.ifError err, "Invalid XML in response"
        test.equal deviceName, data.device.modelName, "modelName should equal name passed to createDevice function"
        test.done()
