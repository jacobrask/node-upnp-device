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

# generate SSDP (HTTPU/HTTPMU) header suiting the message type
makeMessage = (type, config) ->
    # possible headers and values
    headers =
        'HOST': genSsdpUri(config)
        'CACHE-CONTROL': 'max-age=' + config['network']['ssdp']['timeout']
        'LOCATION': genDescriptionUri(config)
        'NT': device.genDeviceType(config)
        'NTS': 'ssdp:alive'
        'SERVER': genServerString(config)
        'USN': 'uuid:' + config['uuid']

    if type is 'NOTIFY'
        useHeaders = [ 'HOST', 'CACHE-CONTROL', 'LOCATION',
                       'NT', 'NTS', 'SERVER', 'USN' ]
    else
        useHeaders = []

    message = [ type + ' * HTTP/1.1' ]
    for header in useHeaders
        message.push(header + ': ' + headers[header])

    # add carriage returns and new lines as required by HTTP spec
    message.push('\r\n')
    message.join('\r\n')


exports.send = (type, config, callback) ->
    message = new Buffer makeMessage(type, config)
    client = dgram.createSocket 'udp4'
    client.bind()
    client.send(message, 0, message.length, 1900, '239.255.255.250')
    client.close()
    callback null
