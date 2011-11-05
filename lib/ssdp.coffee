dgram = require 'dgram'
url = require 'url'
http = require 'http'
config = require './config'
device = require './device'
extend = require('./helpers').extend

announce = exports.announce = (dev, httpServer) ->
    advertise dev, httpServer
    # recommended delay between advertisements is a random interval of less than half of timeout
    setInterval(
        advertise
        Math.floor(Math.random() * ((config.ssdp.timeout / 2) * 1000))
        dev, httpServer
    )

listen = exports.listen = (dev, httpServer) ->
    socket = dgram.createSocket 'udp4', (msg, rinfo) ->
        parseHeaders msg, (err, req) ->
            # these are the ST (search type) values we should respond to
            respondTo = [ 'ssdp:all', 'upnp:rootdevice', config.uuid ]
            if req.method is 'M-SEARCH' and req.headers.st in respondTo
                # specification says to wait between 0 and MX
                # (max 120) seconds before responding
                wait = Math.floor(Math.random() * (parseInt(req.headers.mx) + 1))
                wait = if wait >= 120 then 120 else wait
                setTimeout(
                    answer, wait
                    searchType: req.headers.st, address: rinfo.address, port: rinfo.port
                    dev, httpServer
                )
    socket.addMembership config.ssdp.address
    socket.bind config.ssdp.port

advertise = (dev, httpServer) ->
    sendMessages(
        makeMessage(
            'notify'
            [ 'host', 'cache-control', 'location', 'nt', 'nts', 'server', 'usn' ]
            nt: nt, nts: 'ssdp:alive'
            dev, httpServer
        ) for nt in makeNotificationHeaders(dev)
    )

answer = (req, dev, httpServer) ->
    # unless ssdp:all, respond once with same search type as request's
    sendMessages(
        makeMessage(
            'ok'
            [ 'cache-control', 'ext', 'location', 'server', 'st', 'usn' ]
            st: st
            dev, httpServer
        ) for st in (if req.searchType is 'ssdp:all' then makeNotificationHeaders(dev) else [ req.searchType ])
        req.address
        req.port
    )

# send 3 messages about the device, and then one for each service
makeNotificationHeaders = (dev) ->
    arr = [ 'upnp:rootdevice', config.uuid, device.makeDeviceType(dev.type) ]
    for serviceType in config.devices[dev.type].services
        arr.push device.makeServiceType(serviceType)
    arr

# create a UDP socket, send messages, then close socket
sendMessages = (messages, address, port) ->
    port ?= config.ssdp.port
    socket = dgram.createSocket 'udp4'
    if address?
        socket.setTTL 4
        socket.setMulticastTTL 4
        socket.addMembership config.ssdp.address
    else
        address = config.ssdp.address
    socket.bind(config.ssdp.port)
    done = messages.length
    console.log "Sent messages to #{address}:#{port}"
    for msg in messages
        socket.send msg, 0, msg.length, port, address, ->
            if done-- is 1
                socket.close()

# generate SSDP (HTTPU/HTTPMU) headers suiting the message type
makeMessage = (reqType, useHeaders, customHeaders, dev, httpServer) ->
    # headers with static values
    headers =
        host: "#{config.ssdp.address}:#{config.ssdp.port}"
        'cache-control': "max-age = #{config.ssdp.timeout}"
        location: makeDescriptionUrl httpServer
        server: makeServerString dev
        usn: config.uuid
        ext: ''

    # append NT to USN, except for requests with only uuid as NT
    if customHeaders.nt and customHeaders.nt isnt config.uuid
        headers.usn += '::' + customHeaders.nt
    else if customHeaders.st and customHeaders.st isnt config.uuid
        headers.usn += '::' + customHeaders.st

    headers = extend(headers, customHeaders)
    
    # build message string
    message =
        if reqType is 'ok'
            [ "HTTP/1.1 200 OK" ]
        else
            [ "#{reqType.toUpperCase()} * HTTP/1.1" ]

    for header in useHeaders
        message.push "#{header.toUpperCase()}: #{headers[header]}"
    # add carriage returns and new lines as required by HTTP spec
    message.push '\r\n'
    console.log message
    new Buffer message.join '\r\n'

makeServerString = (dev) ->
    [ "OS/1.0"
      "UPnP/1.0"
      "#{dev.name}/1.0"
    ].join ' '

makeDescriptionUrl = (s) ->
    url.format(
        protocol: 'http:'
        hostname: s.address
        port: s.port
        pathname: '/device/description'
    )

# parse headers using http module parser
parseHeaders = (msg, callback) ->
    parser = http.parsers.alloc()
    parser.reinitialize('request')
    parser.onIncoming = (req) ->
        http.parsers.free(parser)
        callback null, req
    parser.execute msg, 0, msg.length
