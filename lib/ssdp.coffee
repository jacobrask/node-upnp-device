dgram = require 'dgram'
url = require 'url'
http = require 'http'
event = require('events').EventEmitter
device = require './device'
service = require './service'
extend = require('./helpers').extend

event = new event

event.on 'ssdpMsg', (msg) ->
    console.log msg

# Initializes a UPnP Device
start = (config, callback) ->
    
    # Listen for searches
    socket = dgram.createSocket 'udp4'
    socket.on 'message', (msg, rinfo) ->
        parseHeaders msg, (err, req) ->
            # these are the ST values we should respond to
            respondTo = [ 'ssdp:all', 'upnp:rootdevice', config.device.uuid ]
            if req.method is 'M-SEARCH' and req.headers.st in respondTo
                # specification says to wait between 0 and MX (max 120) seconds before responding
                wait = Math.floor(Math.random() * (parseInt(req.headers.mx) + 1))
                wait = if wait >= 120 then 120 else wait
                setTimeout answer, wait, req, (err, msg) ->
                    callback err, msg

    socket.bind(config.network.ssdp.port)

    # generate SSDP (HTTPU/HTTPMU) header suiting the message type
    makeMessage = (reqType, customHeaders, values) ->
        makeServerString = ->
            [
                'OS/1.0 '
                'UPnP/1.0 '
                config['app']['name']
                '/'
                config['app']['version']
            ].join('')

        makeDescriptionUrl = ->
            url.format(
                protocol: 'http:'
                hostname: config['network']['http']['address']
                port: config['network']['http']['port']
                pathname: '/device/description'
            )

        # possible headers and values
        headers =
            'HOST': config['network']['ssdp']['address'] + ':' + config['network']['ssdp']['port']
            'CACHE-CONTROL': 'max-age = ' + config['network']['ssdp']['timeout']
            'LOCATION': makeDescriptionUrl config
            'SERVER': makeServerString config
            'USN': config['device']['uuid']

        # append Notification Type to USN, except for
        # requests with only uuid as NT
        if customHeaders['NT'] and customHeaders['NT'] isnt config['device']['uuid']
            headers['USN'] += '::' + customHeaders['NT']
        else if customHeaders['ST'] and customHeaders['ST'] isnt config['device']['uuid']
            headers['USN'] += '::' + customHeaders['ST']

        headers = extend(headers, customHeaders)

        message = [ reqType + ' * HTTP/1.1' ]
        for header, value of headers
            message.push header + ': ' + value

        # add carriage returns and new lines as required by HTTP spec
        message.push '\r\n'
        message.join '\r\n'

    ssdpSendMessages = (messages, callback) ->
        sendSocket = dgram.createSocket 'udp4'
        sendSocket.setMulticastTTL 4
        sendSocket.bind()
        done = messages.length
        for message in messages
            sendSocket.send message, 0, message.length, config['network']['ssdp']['port'], config['network']['ssdp']['address'], (err) ->
                event.emit 'ssdpMsg', "SSDP message sent on port #{sendSocket.address().port}"
                done--
                if done is 0
                    callback err
                    sendSocket.close()

    makeAdvDelay = ->
        # recommended delay between advertisements is a random interval of less than half of timeout
        max = (config['network']['ssdp']['timeout'] / 2) * 1000
        min = 100
        Math.floor(Math.random() * (max - min))

    advertise = (callback) ->
        # First send three notification messages as per UPnP specification
        messages = []
        messages.push new Buffer makeMessage 'NOTIFY', { NT: 'upnp:rootdevice', NTS: 'ssdp:alive' }, config
        messages.push new Buffer makeMessage 'NOTIFY', { NT: config.device.uuid, NTS: 'ssdp:alive' }, config
        messages.push new Buffer makeMessage 'NOTIFY', { NT: device.makeDeviceType(config), NTS: 'ssdp:alive' }, config
        for serviceType in config.services
            messages.push new Buffer makeMessage 'NOTIFY', { NT: service.makeServiceType(serviceType, config), NTS: 'ssdp:alive' }, config
        ssdpSendMessages messages, (err) ->
            callback err, 'advertisement sent'

    answer = (req, callback) ->
        messages = []
        # if Control Point searched for "ssdp:all" respond 3 times according to spec
        if req.headers.st is 'ssdp:all'
            messages.push new Buffer makeMessage 'NOTIFY', { ST: 'upnp:rootdevice', EXT: '' }, config
            messages.push new Buffer makeMessage 'NOTIFY', { ST: config.device.uuid, EXT: '' }, config
            messages.push new Buffer makeMessage 'NOTIFY', { ST: device.makeDeviceType(config), EXT: '' }, config
        # otherwise respond with same ST value as request
        else
            messages.push new Buffer makeMessage 'NOTIFY', { ST: req.headers.st, EXT: '' }, config

        ssdpSendMessages messages, (err) ->
            callback err, 'answer sent'

    advertise (err) ->
        throw err if err
        setInterval advertise, makeAdvDelay(), (err) ->
            throw err if err

    parseHeaders = (msg, callback) ->
        httpParser = http.parsers.alloc()
        httpParser.reinitialize('request')
        httpParser.onIncoming = (req) ->
            callback null, req
            http.parsers.free(httpParser)
        httpParser.execute msg, 0, msg.length


exports.start = start
