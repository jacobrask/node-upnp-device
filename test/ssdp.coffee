# vim: ts=2 sw=2 sts=2

assert = require 'assert'
dgram = require 'dgram'
upnp = require '../index'

exports['Send out SSDP notifications'] = (test) ->
  device = upnp.createDevice 'MediaServer', 'Test Device'
  socket = dgram.createSocket 'udp4', (msg, rinfo) ->
    device.parseRequest msg, rinfo, (err, req) ->
        test.equal req.method, 'NOTIFY'
        test.equal req.address, device.address
        socket.close()
        test.done()
  socket.setMulticastTTL 4
  # Listen on SSDP broadcast address
  socket.addMembership '239.255.255.250'
  socket.bind 1900
