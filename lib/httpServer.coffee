# HTTP server for descriptions, actions and controls.

fs = require 'fs'
http = require 'http'
url = require 'url'

log = new (require 'log')

{HttpError,ContextError} = require './errors'
helpers = require './helpers'
protocol = require './protocol'
xml = require './xml'

# HTTP servers are device specific, so `@` should be bound to a device.
exports.start = (callback) ->
    # Wrong `this` value.
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


                res.writeHead 200, protocol.makeHeaders.call(@, headers)
                res.write data if data?

            res.end()

    handler = (req, callback) =>

        # URLs are like `/device|service/action/[serviceType]`.
        [category, action, serviceType] = req.url.split('/')[1..]

        serviceControlHandler = =>
            # Service control messages are `POST` requests.
            if req.method isnt 'POST' or not req.headers.soapaction?
                return callback new HttpError 405

            data = ''
            req.on 'data', (chunk) ->
                data += chunk
            req.on 'end', =>
                # `soapaction` header is like `urn:schemas-upnp-org:service:serviceType:v#actionName`
                serviceAction = /:\d#(\w+)"$/.exec(req.headers.soapaction)[1]
                log.debug "#{serviceAction} on #{serviceType} invoked by #{req.client.remoteAddress}."
                @services[serviceType].action serviceAction, data,
                    (err, soapResponse) ->
                        callback err, soapResponse, ext: null

        serviceEventHandler = =>
            log.debug "#{req.method} on #{serviceType} received from #{req.client.remoteAddress}."
            {sid, nt, timeout, callback: cbUrls} = req.headers

            switch req.method

                when 'SUBSCRIBE'
                    if nt? and cbUrls?
                        # New subscription.
                        unless /<http/.test cbUrls
                            return callback new HttpError 412
                        respHeaders = @services[serviceType].subscribe cbUrls.slice(1, -1), timeout
                        callback null, null, respHeaders
                    else if sid? and not (nt? or cbUrls?)
                        # `sid` is subscription ID, so this is a subscription
                        # renewal request.
                        respHeaders = @services[serviceType].renew sid, timeout
                        callback (if respHeaders? then null else new HttpError(412)), null, respHeaders
                    else
                        return callback new HttpError 400

                when 'UNSUBSCRIBE'
                    unless sid?
                        return callback new HttpError 412
                    if nt? or cbUrls?
                        return callback new HttpError 400
                    @services[serviceType].unsubscribe sid
                    # Unsubscription response is `200 OK`.
                    callback null

                else
                    callback new HttpError 405

        # ## Request handler.
        switch category

            when 'device'
                if action isnt 'description'
                    return callback new HttpError 404
                callback null, xml.buildDescription.call @

            when 'service'
                switch action
                    when 'description'
                        fs.readFile("#{__dirname}/services/#{serviceType}.xml", 'utf8'
                            (err, file) -> callback (if err? then new HttpError 500 else null), file)

                    when 'control'
                        serviceControlHandler()

                    when 'event'
                        serviceEventHandler()

                    else
                        callback new HttpError 404

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
