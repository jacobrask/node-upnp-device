# Properties and functionality as specified in [UPnP Device Architecture 1.0] [1].
#
# [1]: http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

"use strict"

async = require 'async'
http = require 'http'
os = require 'os'
url = require 'url'

DeviceControlProtocol = require './DeviceControlProtocol'
helpers = require './helpers'
httpServer = require './httpServer'
ssdp = require './ssdp'

services =
    ConnectionManager: require './services/ConnectionManager'
    ContentDirectory: require './services/ContentDirectory'

class Device extends DeviceControlProtocol

    constructor: (@name, address) ->
        super
        @address = address if address?

    ssdp: { address: '239.255.255.250', port: 1900 }

    # Asynchronous operations to get and set some device properties.
    init: (callback) ->
        async.parallel
            uuid: (callback) => helpers.getUuid @type, @name, callback
            address: (callback) =>
                return callback null, @address if @address?
                helpers.getNetworkIP callback
            port: (callback) => httpServer.start.call @, callback
            (err, res) =>
                return device.emit 'error', err if err?
                @uuid = "uuid:#{res.uuid}"
                @address = res.address
                @httpPort = res.port
                ssdp.start.call @
                @emit 'ready'

    addService: (type) ->
        (@services?={})[type] = new services[type](@)
        @emit 'newService', type

    # Generate HTTP header suiting the SSDP message type.
    makeSSDPMessage: (reqType, customHeaders) ->
        # These headers are included in all SSDP messages. Add them with `null` to
        # `customHeaders` object to get default values from `makeHeaders` function.
        for h in [ 'cache-control', 'server', 'usn', 'location' ]
            customHeaders[h] = null
        headers = @makeHeaders customHeaders

        # Build message string.
        message =
            if reqType is 'ok'
                [ "HTTP/1.1 200 OK" ]
            else
                [ "#{reqType.toUpperCase()} * HTTP/1.1" ]

        for header, value of headers
            message.push "#{header.toUpperCase()}: #{value}"

        # Add carriage returns and newlines as required by HTTP spec.
        message.push '\r\n'
        new Buffer message.join '\r\n'

    # 3 messages about the device, and 1 for each service.
    makeNotificationTypes: ->
        [ 'upnp:rootdevice'
            @uuid
            @makeType()
        ].concat(@makeType(s) for name, s of @services)

    # UPnP Device info for `SERVER` header.
    makeServerString: ->
        [ "#{os.type()}/#{os.release()}"
            "UPnP/#{@upnp.version}"
            "#{@name}/1.0"
        ].join ' '

    # Generate an HTTP header object for HTTP and SSDP messages.
    makeHeaders: (customHeaders) ->
        # Headers which always have the same values (if included).
        defaultHeaders =
            'cache-control': "max-age=1800"
            'content-type': 'text/xml; charset="utf-8"'
            ext: ''
            host: "#{@ssdp.address}:#{@ssdp.port}"
            location: @makeDescriptionUrl()
            server: @makeServerString()
            usn: @uuid + (if @uuid is (customHeaders.nt or customHeaders.st) then '' else '::' + (customHeaders.nt or customHeaders.st))

        headers = {}
        for header of customHeaders
            headers[header.toUpperCase()] = customHeaders[header] or defaultHeaders[header.toLowerCase()]
        headers

    postEvent: (urls, uuid, eventKey, data) ->
        for u in urls
            u = url.parse u
            h =
                nt: 'upnp:event'
                nts: 'upnp:propchange'
                sid: uuid
                seq: eventKey.toString()
                'content-length': Buffer.byteLength data
                'content-type': null
            options =
                host: u.hostname
                port: u.port
                method: 'NOTIFY'
                path: u.pathname
                headers: makeHeaders h
            req = http.request options
            req.on 'error', (err) -> throw err
            req.write data
            req.end()

    parseRequest: (msg, rinfo, callback) ->
        @parseHeaders msg, (err, req) ->
            callback null,
                method: req.method
                maxWait: req.headers.mx
                searchType: req.headers.st
                address: rinfo.address
                port: rinfo.port

    # Parse SSDP headers using the HTTP module parser.
    # This API is not documented and not guaranteed to be stable.
    parseHeaders: (msg, callback) ->
        parser = http.parsers.alloc()
        parser.reinitialize 'request'
        parser.onIncoming = (req) ->
            http.parsers.free parser
            callback null, req
        parser.execute msg, 0, msg.length

    # URL generation.
    makeUrl: (path) ->
        url.format
            protocol: 'http'
            hostname: @address
            port: @httpPort
            pathname: path

    makeDescriptionUrl: -> @makeUrl '/device/description'
    makeContentUrl: (id) -> @makeUrl "/resource/#{id}"

module.exports = Device
