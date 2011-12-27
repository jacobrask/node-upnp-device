# Properties and functionality as specified in [UPnP Device Architecture 1.0] [1].
#
# [1]: http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/
#
# vim: ts=2 sw=2 sts=2

"use strict"

async = require 'async'
{ exec } = require 'child_process'
dgram = require 'dgram'
fs = require 'fs'
http = require 'http'
log = new (require 'log')
os = require 'os'
makeUuid = require 'node-uuid'
xml = require 'xml'

services =
  ConnectionManager: require '../services/ConnectionManager'
  ContentDirectory:  require '../services/ContentDirectory'


DeviceControlProtocol = require '../DeviceControlProtocol'

class Device extends DeviceControlProtocol

  constructor: (@name, address) ->
    super
    @address = address if address?
    @broadcastSocket = dgram.createSocket 'udp4', @ssdpListener
    @broadcastSocket.setMulticastTTL @ssdp.ttl
    @broadcastSocket.addMembership @ssdp.address
    @init()

  ssdp:
    address: '239.255.255.250'
    port: 1900
    timeout: 1800
    ttl: 4
    limit: 5

  services: {}

  # Asynchronous operations to get and set some device properties.
  init: (cb) ->
    async.parallel
      address: (cb) => if @address? then cb null, @address else @getNetworkIP cb
      uuid: (cb) => @getUuid cb
      port: (cb) =>
        @httpServer = http.createServer(@httpListener)
        @httpServer.listen (err) -> cb err, @address().port
      (err, res) =>
        return @emit 'error', err if err?
        @uuid = "uuid:#{res.uuid}"
        @address = res.address
        @httpPort = res.port
        @broadcastSocket.bind @ssdp.port
        @addServices()
        @ssdpAnnounce()
        log.info "Web server listening on http://#{@address}:#{@httpPort}"
        log.debug "UDP socket listening for searches."
        @emit 'ready'

  addServices: ->
    for serviceType in @serviceTypes
      @services[serviceType] = new services[serviceType] @
      @emit 'newService', serviceType

  # Generate HTTP header suiting the SSDP message type.
  makeSsdpMessage: (reqType, customHeaders) ->
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

    message.push "#{h.toUpperCase()}: #{v}" for h, v of headers

    # Add carriage returns and newlines as required by HTTP spec.
    message.push '\r\n'
    new Buffer message.join '\r\n'


  # Make `nt`'s for 3 messages about the device, and 1 for each service.
  makeNotificationTypes: ->
    [ 'upnp:rootdevice', @uuid, @makeType() ]
      .concat(@makeType.call service for name, service of @services)


  # Generate an HTTP header object for HTTP and SSDP messages.
  makeHeaders: (customHeaders) ->
    # Headers which always have the same values (if included).
    defaultHeaders =
      'cache-control': "max-age=1800"
      'content-type': 'text/xml; charset="utf-8"'
      ext: ''
      host: "#{@ssdp.address}:#{@ssdp.port}"
      location: @makeUrl '/device/description'
      server: [
        "#{os.type()}/#{os.release()}"
        "UPnP/#{@upnp.version.join('.')}"
        "#{@name}/1.0" ].join ' '
      usn: @uuid +
        if @uuid is (customHeaders.nt or customHeaders.st) then ''
        else '::' + (customHeaders.nt or customHeaders.st)

    headers = {}
    for header of customHeaders
      headers[header.toUpperCase()] = customHeaders[header] or defaultHeaders[header.toLowerCase()]
    headers


  # Parse SSDP headers using the HTTP module parser.
  # The API is not documented and not guaranteed to be stable.
  parseRequest: (msg, rinfo, cb) ->
    parser = http.parsers.alloc()
    parser.reinitialize 'request'
    parser.onIncoming = (req) ->
      http.parsers.free parser
      cb null,
        method: req.method
        maxWait: req.headers.mx
        searchType: req.headers.st
        address: rinfo.address
        port: rinfo.port
    parser.execute msg, 0, msg.length


  # Attempt UUID persistance of devices across restarts.
  getUuid: (cb) ->
    uuidFile = "#{__dirname}/../../upnp-uuid"
    fs.readFile uuidFile, 'utf8', (err, file) =>
      data =  try
            JSON.parse file
          catch e
            { }
      uuid = data[@type]?[@name]
      unless uuid?
        (data[@type]?={})[@name] = uuid = makeUuid()
        fs.writeFile uuidFile, JSON.stringify data
      # Always call back with UUID, existing or new.
      cb null, uuid


  # We need to get the server's internal network IP to send out in SSDP messages.
  # Only works on Linux and Mac.
  getNetworkIP: (cb) ->
    exec 'ifconfig', (err, stdout) ->
      switch process.platform
        when 'darwin'
          filterRE = /\binet\s+([^\s]+)/g
        when 'linux'
          filterRE = /\binet\b[^:]+:\s*([^\s]+)/g
        else
          return cb new Error "Can't get IP address on this platform."
      isLocal = (address) -> /(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test address
      matches = stdout.match(filterRE) or ''
      ip = (match.replace(filterRE, '$1') for match in matches when !isLocal match)[0]
      err = if ip? then null else new Error "IP address could not be retrieved."
      cb err, ip


  # Build device description XML document.
  buildDescription: ->
    '<?xml version="1.0"?>' + xml [ { root: [
      { _attr: { xmlns: @makeNS() } }
      { specVersion: [ { major: @upnp.version[0] }
                       { minor: @upnp.version[1] } ] }
      { device: [
        { deviceType: @makeType() }
        { friendlyName: "#{@name} @ #{os.hostname()}".substr(0, 64) }
        { manufacturer: 'UPnP Device for Node.js' }
        { modelName: @name.substr(0, 32) }
        { UDN: @uuid }
        { serviceList:
          { service: service.buildServiceElement() } for name, service of @services
        } ] }
    ] } ]


  # HTTP request listener
  httpListener: (req, res) =>
    log.debug "#{req.url} requested by #{req.headers['user-agent']} at #{req.client.remoteAddress}."

    # HTTP request handler.
    handler = (req, cb) =>
      # URLs are like `/device|service/action/[serviceType]`.
      [category, serviceType, action, id] = req.url.split('/')[1..]

      switch category
        when 'device'
          cb null, @buildDescription()
        when 'service'
          @services[serviceType].requestHandler { action, req, id }, cb
        else
          cb new HttpError 404

    handler req, (err, data, headers) =>
      if err?
        # See UDA for error details.
        log.warning "Responded with #{err.code}: #{err.message} for #{req.url}."
        res.writeHead err.code, 'Content-Type': 'text/plain'
        res.write "#{err.code} - #{err.message}"

      else
        # Make a header object for response.
        # `null` means use `makeHeaders` function's default value.
        headers ?= {}
        headers['server'] ?= null
        if data?
          headers['Content-Type'] ?= null
          headers['Content-Length'] ?= Buffer.byteLength(data)

        res.writeHead 200, @makeHeaders headers
        res.write data if data?

      res.end()


  # UDP message queue (to avoid hitting open file descriptor limit).
  ssdpSend: (messages, address, port) ->
    @ssdpMessages.push { messages, address, port }

  ssdpMessages: async.queue (task, callback) =>
    { messages } = task
    address = task.address ? @::ssdp.address
    port = task.port ? @::ssdp.port
    socket = dgram.createSocket 'udp4'
    # Messages with specified destination do not need TTL limit.
    socket.setTTL 4 unless address?
    socket.bind()
    log.debug "Sending #{messages.length} messages to #{address}:#{port}."
    async.concat messages,
      (msg) -> socket.send msg, 0, msg.length, port, address
      ->
        socket.close()
        callback()
  , @::ssdp.limit


  # Listen to SSDP searches.
  ssdpListener: (msg, rinfo) =>

    # Wait between 0 and maxWait seconds before answering to avoid flooding
    # control points.
    answer = (address, port) =>
      @ssdpSend(@makeSsdpMessage('ok',
          st: st, ext: null
        ) for st in @makeNotificationTypes()
        address
        port)

    answerAfter = (maxWait, address, port) ->
      wait = Math.floor Math.random() * (parseInt(maxWait)) * 1000
      log.debug "Replying to search request from #{address}:#{port} in #{wait}ms."
      setTimeout answer, wait, address, port

    respondTo = [ 'ssdp:all', 'upnp:rootdevice', @makeType(), @uuid ]
    @parseRequest msg, rinfo, (err, req) ->
      if req.method is 'M-SEARCH' and req.searchType in respondTo
        answerAfter req.maxWait, req.address, req.port


  # Notify the network about the device.
  ssdpAnnounce: ->
    # Possible subtypes are 'alive' or 'byebye'.
    notify = (subtype) =>
      @ssdpSend(@makeSsdpMessage('notify',
          nt: nt, nts: "ssdp:#{subtype}", host: null
        ) for nt in @makeNotificationTypes())

    # To "kill" any instances that haven't timed out on control points yet,
    # first send byebye message.
    notify 'byebye'
    notify 'alive'

    # Now keep advertising the device at a random interval less than half of
    # SSDP timeout, as per spec.
    makeTimeout = => Math.floor Math.random() * ((@ssdp.timeout / 2) * 1000)
    announce = =>
      setTimeout ->
        notify('alive')
        announce()
      , makeTimeout()


module.exports = Device
