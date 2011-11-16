# HTTP message/header generation.

http = require 'http'
os   = require 'os'
url  = require 'url'

protocol = require './protocol'

unless /upnp-device/.test process.env.NODE_DEBUG
    (console[c] = ->) for c in ['log','info']

# Generate an HTTP header object for HTTP and SSDP messages.
makeHeaders = exports.makeHeaders = (customHeaders) ->
    # SSDP defaults.
    ssdp =
        address: '239.255.255.250'
        port: 1900
        timeout: 1800

    # Headers which always have the same values (if included).
    defaultHeaders =
        'cache-control': "max-age = #{ssdp.timeout}"
        'content-type': 'text/xml; charset="utf-8"'
        ext: ''
        host: "#{ssdp.address}:#{ssdp.port}"
        location: makeDescriptionUrl(@httpAddress, @httpPort)
        server: makeServerString.call @
        usn: @uuid + (if @uuid is (customHeaders.nt or customHeaders.st) then '' else '::' + (customHeaders.nt or customHeaders.st))

    # Always included (add `null` to use `defaultHeaders` value).
    customHeaders['server'] = null
    headers = {}
    for header of customHeaders
        headers[header.toUpperCase()] = customHeaders[header] or defaultHeaders[header.toLowerCase()]
    headers

# Generate HTTP header suiting the SSDP message type.
exports.makeSSDPMessage = (reqType, customHeaders) ->

    # These headers are included in all SSDP messages. Add them with `null` to
    # `customHeaders` object to get default values from `makeHeaders` function.
    for h in ['cache-control','server','usn','location']
        customHeaders[h] = null
    headers = makeHeaders.call @, customHeaders

    # Build message string.
    message =
        if reqType is 'ok'
            [ "HTTP/1.1 200 OK" ]
        else
            [ "#{reqType.toUpperCase()} * HTTP/1.1" ]

    for header, value of headers
        message.push "#{header.toUpperCase()}: #{value}"

    console.log "Made #{reqType} message:", message.join(' | ')

    # Add carriage returns and newlines as required by HTTP spec.
    message.push '\r\n'
    new Buffer message.join '\r\n'

# 3 messages about the device, and 1 for each service.
exports.makeNotificationTypes = ->
    [ 'upnp:rootdevice'
      @uuid
      protocol.makeDeviceType.call @
    ].concat(
        protocol.makeServiceType.call(s) for name, s of @services
    )

# UPnP Device info for `SERVER` header.
makeServerString = ->
    [ "#{os.type()}/#{os.release()}"
      "UPnP/#{@upnpVersion}"
      "#{@name}/1.0"
    ].join ' '


exports.parseRequest = (msg, rinfo, callback) ->
    parseHeaders msg, (err, req) ->
        callback null, {
            method: req.method
            maxWait: req.headers.mx
            searchType: req.headers.st
            address: rinfo.address
            port: rinfo.port
        }

# Parse SSDP headers using the HTTP module parser.
# This API is not documented and not guaranteed to be stable.
parseHeaders = (msg, callback) ->
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

# Use http module's `STATUS_CODES` static to get error messages.
class HttpError extends Error
    constructor: (@code) ->
        @message = http.STATUS_CODES[@code]
exports.HttpError = HttpError
