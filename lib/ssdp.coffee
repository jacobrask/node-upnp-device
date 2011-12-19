# SSDP server/client. Messages use HTTP and are defined in the
# DeviceControlProtocol class.
#
# vim: ts=2 sw=2 sts=2

"use strict"

async = require 'async'
dgram = require 'dgram'
log = new (require 'log')
os = require 'os'

# `@` should be bound to a Device.
exports.start = ->
  listen = =>
    socket = dgram.createSocket 'udp4', (msg, rinfo) =>
      # Message listener.
      @parseRequest msg, rinfo, (err, req) ->
        if req.method is 'M-SEARCH' and shouldRespond(req.searchType)
          answerAfter req.maxWait, req.address, req.port
    socket.setMulticastTTL 4
    socket.addMembership '239.255.255.250'
    socket.bind 1900
    log.debug "UDP socket listening for searches."

  # Wait between 0 and maxWait seconds before answering to avoid flooding
  # control points.
  answerAfter = (maxWait, address, port) ->
    wait = Math.floor(Math.random() * (parseInt(maxWait)) * 1000)
    log.debug "Replying to search request from #{address}:#{port} in #{wait}ms."
    setTimeout answer, wait, address, port

  shouldRespond = (searchType) =>
    searchType in [
      'ssdp:all'
      'upnp:rootdevice'
       @makeType()
       @uuid ]

  # Create a UDP socket, send messages, then close socket.
  sendMessages = (messages, address = '239.255.255.250', port = 1900) ->
    socket = dgram.createSocket 'udp4'
    # Messages with specified destination do not need TTL limit.
    socket.setTTL 4 unless address?
    socket.bind()
    log.debug "Sending #{messages.length} messages to #{address}:#{port}."
    async.concat messages,
      (msg) -> socket.send msg, 0, msg.length, port, address
      -> socket.close()

  announce = (timeout = 1800) ->
    # To "kill" any instances that haven't timed out on control points yet,
    # first send byebye message.
    notify 'byebye'
    notify 'alive'

    # Now keep advertising the device. A random interval, but less than
    # half of SSDP timeout, is recommended.
    setInterval notify,
      Math.floor Math.random() * ((timeout / 2) * 1000)
      'alive'

  # Possible subtypes are 'alive' or 'byebye'.
  notify = (subtype) =>
    sendMessages(
      @makeSSDPMessage('notify',
        nt: nt, nts: "ssdp:#{subtype}", host: null
      ) for nt in @makeNotificationTypes()
    )

  answer = (address, port) =>
    sendMessages(
      @makeSSDPMessage('ok',
        st: st, ext: null
      ) for st in @makeNotificationTypes()
      address
      port
    )

  listen()
  announce()
