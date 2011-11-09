dgram = require 'dgram'
http  = require 'http'
os    = require 'os'
url   = require 'url'

config  = require './config'
{debug} = require './helpers'

announce = exports.announce = (device, webServer) ->
    # to "kill" any instances that haven't timed out on control points yet, first send byebye message
    byebye device, webServer
    alive device, webServer
    # recommended delay between advertisements is a random interval of less than half of timeout
    setInterval(
        alive
        Math.floor(Math.random() * ((config.ssdp.timeout / 2) * 1000))
        device, webServer
    )

# create socket listening for search requests
listen = exports.listen = (device, webServer) ->
    socket = dgram.createSocket 'udp4', (msg, rinfo) ->
        parseHeaders msg, (err, req) ->
            # these are the ST (search type) values we should respond to
            respondTo = [ 'ssdp:all', 'upnp:rootdevice', device.makeDeviceType(), config.uuid ]
            if req.method is 'M-SEARCH' and req.headers.st in respondTo
                debug "Received search request from #{rinfo.address}:#{rinfo.port}"
                # specification says to wait between 0 and MX
                # (max 120) seconds before responding
                wait = Math.floor(Math.random() * (parseInt(req.headers.mx) + 1))
                wait = if wait >= 120 then 120 else wait
                setTimeout(
                    answer, wait
                    searchType: req.headers.st, address: rinfo.address, port: rinfo.port
                    device, webServer
                )
    socket.addMembership config.ssdp.address
    socket.bind config.ssdp.port

# initial announcement
alive = (device, webServer) ->
    sendMessages(
        makeMessage(
            'notify'
            nt: nt, nts: 'ssdp:alive', host: null
            device, webServer
        ) for nt in makeNotificationHeaders(device)
    )

# answer to search requests
answer = (req, device, webServer) ->
    # according to spec responses which are not ssdp:all should just reply
    # once mirroring the ST value, but that didn't work with actual control points
    sendMessages(
        makeMessage(
            'ok'
            st: st, ext: null
            device, webServer
        ) for st in makeNotificationHeaders(device)
        req.address
        req.port
    )

byebye = (device, webServer) ->
    sendMessages(
        makeMessage(
            'notify'
            nt: nt, nts: 'ssdp:byebye', host: null
            device, webServer
        ) for nt in makeNotificationHeaders(device)
    )

# send 3 messages about the device, and then one for each service
makeNotificationHeaders = (device) ->
    [ 'upnp:rootdevice'
      config.uuid
      device.makeDeviceType()
    ].concat(device.makeServiceType(s) for s in Object.keys(device.services))

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
    socket.bind config.ssdp.port
    debug "Sending #{messages.length} messages from #{config.ssdp.port} to #{address}:#{port}"
    done = messages.length
    for msg in messages
        socket.send msg, 0, msg.length, port, address, ->
            if done-- is 1
                socket.close()

# generate SSDP (HTTPU/HTTPMU) headers suiting the message type
makeMessage = (reqType, customHeaders, device, webServer) ->
    # headers with static values
    defaultHeaders =
        host: "#{config.ssdp.address}:#{config.ssdp.port}"
        'cache-control': "max-age = #{config.ssdp.timeout}"
        location: makeDescriptionUrl webServer
        server: makeServerString device
        ext: ''
        usn: config.uuid + (if config.uuid is (customHeaders.nt or customHeaders.st) then '' else '::' + (customHeaders.nt or customHeaders.st))

    # these headers are included in every request, merge them with the request specific headers
    includeHeaders = ['cache-control','server','usn','location'].concat Object.keys customHeaders

    # build message string
    message =
        if reqType is 'ok'
            [ "HTTP/1.1 200 OK" ]
        else
            [ "#{reqType.toUpperCase()} * HTTP/1.1" ]

    for header in includeHeaders
        message.push "#{header.toUpperCase()}: #{customHeaders[header] or defaultHeaders[header]}"

    debug message.join '\n      '
    # add carriage returns and new lines as required by HTTP spec
    message.push '\r\n'
    new Buffer message.join '\r\n'

makeServerString = (device) ->
    [ "#{os.type()}/#{os.release()}"
      "UPnP/#{device.schema.upnpVersion}"
      "#{device.name}/1.0"
    ].join ' '

makeDescriptionUrl = (s) ->
    url.format(
        protocol: 'http:'
        hostname: s.address
        port: s.port
        pathname: '/device/description'
    )

# parse headers using http module parser
# this api is not documented nor stable, might break in the future
parseHeaders = (msg, callback) ->
    parser = http.parsers.alloc()
    parser.reinitialize 'request'
    parser.onIncoming = (req) ->
        http.parsers.free parser
        callback null, req
    parser.execute msg, 0, msg.length
