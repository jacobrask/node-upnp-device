# HTTP over UDP helper functions

http = require 'http'
os   = require 'os'
url  = require 'url'

protocol = require './protocol'

(console[c] = ->) for c in ['log','info'] unless /upnp-device/.test process.env.NODE_DEBUG

httpu = {}

# generate HTTP headers suiting the message type
httpu.makeMessage = (reqType, customHeaders, device, ssdp) ->
    console.log "Making #{reqType} message with #{(key + ':' + val) for key, val of customHeaders}"
    # SSDP defaults
    ssdp ?= {}
    ssdp.address = '239.255.255.250'
    ssdp.port = 1900
    ssdp.timeout = 1800

    # headers with static values
    defaultHeaders =
        host: "#{ssdp.address}:#{ssdp.port}"
        'cache-control': "max-age = #{ssdp.timeout}"
        location: makeDescriptionUrl(device.httpAddress, device.httpPort)
        server: httpu.makeServerString(device.name)
        ext: ''
        usn: device.uuid + (if device.uuid is (customHeaders.nt or customHeaders.st) then '' else '::' + (customHeaders.nt or customHeaders.st))

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

    # add carriage returns and new lines as required by HTTP spec
    message.push '\r\n'
    new Buffer message.join '\r\n'

# send 3 messages about the device, and then one for each service
httpu.makeNotificationTypes = (device) ->
    [ 'upnp:rootdevice'
      device.uuid
      protocol.makeDeviceType.call device
    ].concat(protocol.makeServiceType(s, device.version) for s in Object.keys(device.services))

httpu.parseRequest = (msg, rinfo, callback) ->
    httpu.parseHeaders msg, (err, req) ->
        callback null, {
            method: req.method
            maxWait: req.headers.mx
            searchType: req.headers.st
            address: rinfo.address
            port: rinfo.port
        }

# parse headers using http module parser
# this api is not documented nor stable, might break in the future
httpu.parseHeaders = (msg, callback) ->
    parser = http.parsers.alloc()
    parser.reinitialize 'request'
    parser.onIncoming = (req) ->
        http.parsers.free parser
        callback null, req
    parser.execute msg, 0, msg.length

httpu.makeServerString = (deviceName, upnpVersion = '1.0') ->
    [ "#{os.type()}/#{os.release()}"
      "UPnP/#{upnpVersion}"
      "#{deviceName}/1.0"
    ].join ' '

makeDescriptionUrl = (address, port)->
    url.format(
        protocol: 'http:'
        hostname: address
        port: port
        pathname: '/device/description'
    )

module.exports = httpu
