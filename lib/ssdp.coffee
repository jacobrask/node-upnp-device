dgram = require 'dgram'
os    = require 'os'

httpu    = require './httpu'
protocol = require './protocol'

(console[c] = ->) for c in ['log','info'] unless /upnp-device/.test process.env.NODE_DEBUG

ssdp = {}

ssdp.announce = (device, timeout = 1800) ->
    # to "kill" any instances that haven't timed out on control points yet, first send byebye message
    notify 'byebye', device
    notify 'alive', device

    # recommended delay between advertisements is a random interval of less than half of timeout
    setInterval(
        notify
        Math.floor(Math.random() * ((timeout / 2) * 1000))
        'alive'
        device
    )

# create socket listening for search requests
ssdp.listen = (device, port = 1900, address = '239.255.255.250') ->
    socket = dgram.createSocket 'udp4', (msg, rinfo) =>
        httpu.parseRequest msg, rinfo, (err, req) =>
            if req.method is 'M-SEARCH' and shouldRespond(req.searchType, device)
                answerAfter(req.maxWait, req.address, req.port, device)
    socket.addMembership(address)
    socket.bind(port)

shouldRespond = (searchType, device) ->
    searchType in [
        'ssdp:all'
        'upnp:rootdevice'
         protocol.makeDeviceType(device.type, device.version)
         device.uuid ]

answerAfter = (maxWait, address, port, device) ->
    # specification says to wait between 0 and MX seconds before reply
    wait = Math.floor(Math.random() * (parseInt(maxWait)) * 1000)
    console.info "Replying to search request from #{address}:#{port} in #{wait}ms"
    setTimeout(answer, wait, address, port, device)

notify = (subtype, device) ->
    sendMessages(
        httpu.makeMessage(
            'notify'
            nt: nt, nts: "ssdp:#{subtype}", host: null
            device
        ) for nt in httpu.makeNotificationTypes(device)
    )

answer = (address, port, device) ->
    sendMessages(
        httpu.makeMessage(
            'ok'
            st: st, ext: null
            device
        ) for st in httpu.makeNotificationTypes(device)
        address
        port
    )

# create a UDP socket, send messages, then close socket
sendMessages = (messages, address = '239.255.255.250', port = 1900) ->
    socket = dgram.createSocket 'udp4'
    socket.bind port
    console.info "Sending #{messages.length} messages to #{address}:#{port}"
    done = messages.length
    for msg in messages
        socket.send msg, 0, msg.length, port, address, ->
            if done-- is 1
                socket.close()

module.exports = ssdp
