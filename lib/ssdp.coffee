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
        @listen()

    announce: ->
        # to "kill" any instances that haven't timed out on control points yet, first send byebye message
        @notify('byebye')
        @notify('alive')

        # recommended delay between advertisements is a random interval of less than half of timeout
        setInterval(
            @alive
            Math.floor(Math.random() * ((@timeout / 2) * 1000))
        )

    # create socket listening for search requests
    listen: ->
        socket = dgram.createSocket 'udp4', (msg, rinfo) =>
            httpu.parseRequest msg, rinfo, (err, req) =>
                if req.method is 'M-SEARCH' and req.searchType in @respondTo
                    @answerAfter(req.maxWait, req.address, req.port)
        socket.addMembership(@mcAddress)
        socket.bind(@mcPort)

    answerAfter: (maxWait, address, port) ->
        # specification says to wait between 0 and MX seconds before reply
        wait = Math.floor(Math.random() * (parseInt(maxWait)) * 1000)
        helpers.debug "Replying to search request from #{address}:#{port} in #{wait}ms"
        setTimeout(@answer, wait, address, port)

    notify: (subtype) ->
        @sendMessages(
            httpu.makeMessage(
                'notify'
                nt: nt, nts: "ssdp:#{subtype}", host: null
                @device
            ) for nt in httpu.makeNotificationTypes(@device)
        )

    answer: (address, port) =>
        @sendMessages(
            httpu.makeMessage(
                'ok'
                st: st, ext: null
                @device
            ) for st in httpu.makeNotificationTypes(@device)
            address
            port
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
