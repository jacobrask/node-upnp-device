dgram = require 'dgram'
http  = require 'http'
os    = require 'os'
url   = require 'url'

{debug} = require './helpers'

class Ssdp

    constructor: (@device) ->
        @timeout = 1800
        @respondTo = [ 'ssdp:all', 'upnp:rootdevice', @device.makeDeviceType(), @device.uuid ]
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
        @parseHeaders msg, (err, req) =>
            # these are the ST (search type) values we should respond to
            if req.method is 'M-SEARCH' and req.headers.st in @respondTo
                debug "Received search request from #{rinfo.address}:#{rinfo.port}"
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
            @makeMessage(
                'notify'
                nt: nt, nts: 'ssdp:alive', host: null
            ) for nt in @makeNotificationHeaders()
        )

    answer: ->
        @sendMessages(
            @makeMessage(
                'ok'
                st: st, ext: null
            ) for st in @makeNotificationHeaders()
            address
            port
        )

    byebye: ->
        @sendMessages(
            @makeMessage(
                'notify'
                nt: nt, nts: 'ssdp:byebye', host: null
            ) for nt in @makeNotificationHeaders()
        )

    # send 3 messages about the device, and then one for each service
    makeNotificationHeaders: ->
        [ 'upnp:rootdevice'
          @device.uuid
          @device.makeDeviceType()
        ].concat(@device.makeServiceType(s) for s in Object.keys(@device.services))

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
        debug "Sending #{messages.length} messages to #{address}:#{port}"
        done = messages.length
        for msg in messages
            socket.send msg, 0, msg.length, port, address, ->
                if done-- is 1
                    socket.close()

    # generate SSDP (HTTPU/HTTPMU) headers suiting the message type
    makeMessage: (reqType, customHeaders) ->
        # headers with static values
        defaultHeaders =
            host: "#{@mcAddress}:#{@mcPort}"
            'cache-control': "max-age = #{@timeout}"
            location: @makeDescriptionUrl()
            server: @device.makeServerString()
            ext: ''
            usn: @device.uuid + (if @device.uuid is (customHeaders.nt or customHeaders.st) then '' else '::' + (customHeaders.nt or customHeaders.st))

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

        debug message.join '|'
        # add carriage returns and new lines as required by HTTP spec
        message.push '\r\n'
        new Buffer message.join '\r\n'

    makeDescriptionUrl: ->
        url.format(
            protocol: 'http:'
            hostname: @device.httpServerAddress
            port: @device.httpServerPort
            pathname: '/device/description'
        )

    # parse headers using http module parser
    # this api is not documented nor stable, might break in the future
    parseHeaders: (msg, callback) ->
        parser = http.parsers.alloc()
        parser.reinitialize 'request'
        parser.onIncoming = (req) ->
            http.parsers.free parser
            callback null, req
        parser.execute msg, 0, msg.length

exports.create = (device) -> new Ssdp(device)
