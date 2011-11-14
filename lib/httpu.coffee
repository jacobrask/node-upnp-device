# HTTP message/header generation.

http = require 'http'
os   = require 'os'
url  = require 'url'

protocol = require './protocol'

unless /upnp-device/.test process.env.NODE_DEBUG
    (console[c] = ->) for c in ['log','info']

httpu = {}

# Generate HTTP headers suiting the SSDP message type.
httpu.makeSSDPMessage = (reqType, customHeaders) ->
    console.log "Making #{reqType} message with
 #{(key + ':' + val) for key, val of customHeaders}"
    # SSDP defaults.
    ssdp =
        address: '239.255.255.250'
        port: 1900
        timeout: 1800

    # Headers with static values.
    defaultHeaders =
        host: "#{ssdp.address}:#{ssdp.port}"
        'cache-control': "max-age = #{ssdp.timeout}"
        location: makeDescriptionUrl(@httpAddress, @httpPort)
        server: httpu.makeServerString.call @
        ext: ''
        usn: @uuid + (if @uuid is (customHeaders.nt or customHeaders.st) then '' else '::' + (customHeaders.nt or customHeaders.st))

    # These headers are included in every request.
    includeHeaders = ['cache-control','server','usn','location'].concat(
        Object.keys customHeaders
    )

    # Build message string.
    message =
        if reqType is 'ok'
            [ "HTTP/1.1 200 OK" ]
        else
            [ "#{reqType.toUpperCase()} * HTTP/1.1" ]

    for header in includeHeaders
        message.push "#{header.toUpperCase()}:
 #{customHeaders[header] or defaultHeaders[header]}"

    # Add carriage returns and newlines as required by HTTP spec.
    message.push '\r\n'
    new Buffer message.join '\r\n'

# 3 messages about the device, and 1 for each service.
httpu.makeNotificationTypes = ->
    [ 'upnp:rootdevice'
      @uuid
      protocol.makeDeviceType.call @
    ].concat(
        protocol.makeServiceType(s, @version) for s in Object.keys(@services)
    )

# UPnP Device info for `SERVER` header.
httpu.makeServerString = ->
    [ "#{os.type()}/#{os.release()}"
      "UPnP/#{@upnpVersion}"
      "#{@name}/1.0"
    ].join ' '


httpu.parseRequest = (msg, rinfo, callback) ->
    httpu.parseHeaders msg, (err, req) ->
        callback null, {
            method: req.method
            maxWait: req.headers.mx
            searchType: req.headers.st
            address: rinfo.address
            port: rinfo.port
        }

# Parse SSDP headers using the HTTP module parser.
# This API is not documented and not guaranteed to be stable.
httpu.parseHeaders = (msg, callback) ->
    parser = http.parsers.alloc()
    parser.reinitialize 'request'
    parser.onIncoming = (req) ->
        http.parsers.free parser
        callback null, req
    parser.execute msg, 0, msg.length


makeDescriptionUrl = (address, port)->
    url.format(
        protocol: 'http:'
        hostname: address
        port: port
        pathname: '/device/description'
    )

module.exports = httpu
