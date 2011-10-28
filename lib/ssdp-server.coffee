dgram = require 'dgram'
url = require 'url'
device = require './device'

genServerString = (config) ->
    [
        'OS/1.0 '
        'UPnP/1.0 '
        config['app']['name']
        '/'
        config['app']['version']
    ].join('')

genDescriptionUri = (config) ->
    url.format(
        protocol: 'http:'
        hostname: config['network']['http']['address']
        port: config['network']['http']['port']
        pathname: '/description.xml'
    )

genSsdpUri = (config) ->
    config['network']['ssdp']['address'] + ':' + config['network']['ssdp']['port']

exports.send = (type, config, callback) ->
    client = dgram.createSocket 'udp4'
    client.bind()
    message = []
    message.push type + ' * HTTP/1.1'
    message.push 'HOST: ' + genSsdpUri(config)
    message.push 'CACHE-CONTROL: max-age=' + config['network']['ssdp']['timeout']
    message.push 'LOCATION: ' + genDescriptionUri(config)
    message.push 'NT: ' + device.genDeviceType(config)
    message.push 'NTS: ssdp:alive'
    message.push 'SERVER: ' + genServerString(config)
    message.push 'USN: uuid:' + config['uuid']
    message.push '\r\n'
    console.log message.join('\r\n')
    message = new Buffer message.join('\r\n')
    client.send(message, 0, message.length, 1900, '239.255.255.250')
    client.close()
    callback null
