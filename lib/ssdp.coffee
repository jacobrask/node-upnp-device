dgram = require 'dgram'
os    = require 'os'

helpers  = require './helpers'
httpu    = require './httpu'
protocol = require './protocol'

class Ssdp

    constructor: (@device) ->
        @timeout = 1800
        @respondTo = [
            'ssdp:all'
            'upnp:rootdevice'
            protocol.makeDeviceType(@device.type, @device.version)
            @device.uuid ]
        @mcPort = 1900
        @mcAddress = '239.255.255.250'
        @mcSocket = dgram.createSocket 'udp4', @listener
        @mcSocket.addMembership @mcAddress
        @mcSocket.bind @mcPort

    announce: ->
        # to "kill" any instances that haven't timed out on control points yet, first send byebye message
        @byebye()
        @alive()
        # recommended delay between advertisements is a random interval of less than half of timeout
        setInterval(
            @alive
            Math.floor(Math.random() * ((@timeout / 2) * 1000))
        )

    # create socket listening for search requests
    listener: (msg, rinfo) =>
        httpu.parseHeaders msg, (err, req) =>
            # these are the ST (search type) values we should respond to
            if req.method is 'M-SEARCH' and req.headers.st in @respondTo
                helpers.debug "Received search request from #{rinfo.address}:#{rinfo.port}"
                # specification says to wait between 0 and MX
                # (max 120) seconds before responding
                wait = Math.floor(Math.random() * (parseInt(req.headers.mx) + 1))
                wait = if wait >= 120 then 120 else wait
                setTimeout(
                    @answer, wait
                    address: rinfo.address, port: rinfo.port
                )

    # initial announcement
    alive: ->
        @sendMessages(
            httpu.makeMessage(
                'notify'
                nt: nt, nts: 'ssdp:alive', host: null
                @device
            ) for nt in httpu.makeNotificationHeaders(@device)
        )

    answer: ->
        @sendMessages(
            httpu.makeMessage(
                'ok'
                st: st, ext: null
                @device
            ) for st in httpu.makeNotificationHeaders(@device)
            address
            port
        )

    byebye: ->
        @sendMessages(
            httpu.makeMessage(
                'notify'
                nt: nt, nts: 'ssdp:byebye', host: null
                @device
            ) for nt in httpu.makeNotificationHeaders(@device)
        )


    # create a UDP socket, send messages, then close socket
    sendMessages: (messages, address, port) ->
        port ?= @mcPort
        socket = dgram.createSocket 'udp4'
        if address?
            socket.setTTL 4
            socket.setMulticastTTL 4
            socket.addMembership @mcAddress
        else
            address = @mcAddress
        socket.bind @mcPort
        helpers.debug "Sending #{messages.length} messages to #{address}:#{port}"
        done = messages.length
        for msg in messages
            socket.send msg, 0, msg.length, port, address, ->
                if done-- is 1
                    socket.close()

exports.create = (device) -> new Ssdp(device)
