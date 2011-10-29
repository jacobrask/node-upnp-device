dgram = require 'dgram'
url = require 'url'
event = require('events').EventEmitter
device = require './device'

event = new event

event.on 'ssdpMsg', (msg) ->
    console.log msg

# Initializes a UPnP Device
start = (config, callback) ->
    
    # generate SSDP (HTTPU/HTTPMU) header suiting the message type
    makeMessage = (type, nt, nts) ->
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
                pathname: '/devices/root.xml'
            )

        # possible headers and values
        headers =
            'HOST': config['network']['ssdp']['address'] + ':' + config['network']['ssdp']['port']
            'CACHE-CONTROL': 'max-age=' + config['network']['ssdp']['timeout']
            'LOCATION': makeDescriptionUrl config
            'NT': nt
            'NTS': 'ssdp:' + nts
            'SERVER': makeServerString config
            'USN': config['device']['uuid']

        # append Notification Type to USN, except for
        # requests with only uuid as NT
        unless nt is config['device']['uuid']
            headers['USN'] += '::' + nt

        switch type
            when 'NOTIFY'
                useHeaders = [ 'HOST', 'CACHE-CONTROL', 'LOCATION',
                               'NT', 'NTS', 'SERVER', 'USN' ]
            else
                useHeaders = []

        message = [ type + ' * HTTP/1.1' ]
        for header in useHeaders
            message.push header + ': ' + headers[header]

        # add carriage returns and new lines as required by HTTP spec
        message.push '\r\n'
        message.join '\r\n'


    ssdpSend = (socket, message, callback) ->
        socket.send message, 0, message.length, config['network']['ssdp']['port'], config['network']['ssdp']['address'], (err) ->
            event.emit 'ssdpMsg', "SSDP message sent on port #{socket.address().port}"
            callback err

    makeAdvDelay = ->
        # recommended delay between advertisements is a random interval of less than half of timeout
        max = (config['network']['ssdp']['timeout'] / 2) * 1000
        min = 100
        Math.floor(Math.random() * (max - min))

    advertise = (callback) ->
        socket = dgram.createSocket 'udp4'
        socket.bind()
        socket.setBroadcast 1
        socket.setMulticastTTL 2
        # First send three notification messages as per UPnP specification
        messages = []
        messages.push new Buffer makeMessage 'NOTIFY', 'upnp:rootdevice', 'all', config
        messages.push new Buffer makeMessage 'NOTIFY', config['device']['uuid'], 'all', config
        messages.push new Buffer makeMessage 'NOTIFY', device.makeDeviceType(config), 'all', config
        done = messages.length
        for message in messages
            ssdpSend socket, message, (err) ->
                done--
                if done is 0
                    callback err, socket.address().port
                    socket.close()

    advertise (err, port) ->
        setInterval advertise, makeAdvDelay(), (err, port) ->
            callback err

exports.start = start
