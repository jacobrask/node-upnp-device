# HTTP server for descriptions, actions and controls.
#
# vim: ts=2 sw=2 sts=2

"use strict"

fs   = require 'fs'
http = require 'http'
log  = new (require 'log')
url  = require 'url'

{ HttpError, ContextError } = require './errors'

# HTTP servers are device specific, so `@` should be bound to a device.
exports.start = (cb) ->

  # ## Request listener.
  server = http.createServer (req, res) =>
    log.debug "#{req.url} requested by #{req.headers['user-agent']} at #{req.client.remoteAddress}."

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
        headers[server] ?= null
        if data?
          headers['Content-Type'] ?= null
          headers['Content-Length'] ?= Buffer.byteLength(data)

        res.writeHead 200, @makeHeaders headers
        res.write data if data?

      res.end()

  # ## Request handler.
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


  server.listen (err) ->
    port = server.address().port
    log.info "Web server listening on port #{port}."
    cb err, port
