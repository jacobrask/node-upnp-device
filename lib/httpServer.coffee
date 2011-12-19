# HTTP server for descriptions, actions and controls.

fs   = require 'fs'
http = require 'http'
log  = new (require 'log')
url  = require 'url'

{HttpError,ContextError} = require './errors'

# HTTP servers are device specific, so `@` should be bound to a device.
exports.start = (callback) ->
    return callback new ContextError if @start? or @ is global

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
    handler = (req, callback) =>

        # URLs are like `/device|service/action/[serviceType]`.
        [category, action, serviceType] = req.url.split('/')[1..]

        switch category

            when 'device'
                return callback new HttpError 404 unless action is 'description'
                callback null, @buildDescription()

            when 'service'
                @services[serviceType].requestHandler action, req, callback

            when 'resource'
                @services.ContentDirectory.fetchObject action, (err, object) ->
                    return callback new HttpError 500 if err
                    fs.readFile object.location, (err, file) ->
                        return callback new HttpError 500 if err
                        callback null, file,
                            'Content-Type': object.contenttype
                            'Content-Length': object.filesize

            else
                callback new HttpError 404


    server.listen (err) ->
        port = server.address().port
        log.info "Web server listening on port #{port}."
        callback err, port
