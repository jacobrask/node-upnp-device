# SSDP helpers. Messages use HTTP and are generated in the `httpu` module.

dgram = require 'dgram'
os    = require 'os'

httpu    = require './httpu'
protocol = require './protocol'

unless /upnp-device/.test process.env.NODE_DEBUG
    (console[c] = ->) for c in ['log','info']

# `@` should be bound to a Device.
exports.start = (callback) ->

    listen = =>
        socket = dgram.createSocket 'udp4', (msg, rinfo) =>
            # Message listener.
            httpu.parseRequest msg, rinfo, (err, req) =>
                if req.method is 'M-SEARCH' and shouldRespond(req.searchType)
                    answerAfter(req.maxWait, req.address, req.port)
        socket.setMulticastTTL 4
        socket.addMembership '239.255.255.250'
        socket.bind 1900
        console.info "UDP socket listening for searches."

    shouldRespond = (searchType) =>
        searchType in [
            'ssdp:all'
            'upnp:rootdevice'
             protocol.makeDeviceType.call @
             @uuid ]

    # Wait between 0 and maxWait seconds before answering to avoid
    # flooding control points.
    answerAfter = (maxWait, address, port) =>
        wait = Math.floor(Math.random() * (parseInt(maxWait)) * 1000)
        console.info "Replying to search request from #{address}:#{port}
 in #{wait}ms."
        setTimeout(answer, wait, address, port)


    # Create a UDP socket, send messages, then close socket.
    sendMessages = (messages, address = '239.255.255.250', port = 1900) ->
        socket = dgram.createSocket 'udp4'
        # Messages with specified destination do not need TTL limit.
        socket.setTTL 4 unless address?
        socket.bind()
        console.info "Sending #{messages.length} messages
 to #{address}:#{port}."
        done = messages.length
        for msg in messages
            socket.send msg, 0, msg.length, port, address, ->
                if done-- is 1
                    socket.close()

    announce = (timeout = 1800) =>
        # To "kill" any instances that haven't timed out on control points yet,
        # first send byebye message.
        notify 'byebye'
        notify 'alive'

        # Now keep advertising the device. A random interval, but less than
        # half of SSDP timeout, is recommended.
        setInterval(
            notify
            Math.floor(Math.random() * ((timeout / 2) * 1000))
            'alive'
        )

    # Possible subtypes are 'alive' or 'byebye'.
    notify = (subtype) =>
        sendMessages(
            httpu.makeSSDPMessage.call(
                @
                'notify'
                nt: nt, nts: "ssdp:#{subtype}", host: null
            ) for nt in httpu.makeNotificationTypes.call @
        )

    answer = (address, port) =>
        sendMessages(
            httpu.makeSSDPMessage.call(
                @
                'ok'
                st: st, ext: null
            ) for st in httpu.makeNotificationTypes.call @
            address
            port
        )


    listen()
    announce()
