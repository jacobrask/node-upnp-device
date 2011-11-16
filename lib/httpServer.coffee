# HTTP helpers. If they depend on Device state they will be exported and
# added as Device prototypes.

fs   = require 'fs'
http = require 'http'
url  = require 'url'

helpers = require './helpers'
httpu   = require './httpu'
xml     = require './xml'
{HttpError} = httpu

unless /upnp-device/.test process.env.NODE_DEBUG
    (console[c] = ->) for c in ['log', 'info']

# `@` should be bound to a Device.
exports.start = (callback) ->

    server = http.createServer (req, res) =>
        # Request listener.
        console.log "#{req.url} requested by #{req.headers['user-agent']}
 at #{req.client.remoteAddress}."
        handler req, (err, data, customHeaders) =>
            if err?
                console.warn "Responded with #{err.code}: #{err.message} for #{req.url}."
                res.writeHead err.code, 'Content-Type': 'text/plain'
                res.write "#{err.code} - #{err.message}"
            else
                # Make a header object for response.
                # `null` means use default value.
                headers = {}
                if data?
                    headers['Content-Type'] = null
                    headers['Content-Length'] = Buffer.byteLength(data)
                for header, value of customHeaders
                    headers[header] = value
                res.writeHead 200, httpu.makeHeaders.call(@, headers)
                res.write data if data?
            res.end()

    handler = (req, callback) =>
        # URLs are like `/device|service/action/[serviceType]`.
        [category, action, serviceType] = req.url.split('/')[1..]
        switch category
            when 'device'
                if action isnt 'description'
                    return callback new HttpError 404
                @_buildDescription (err, desc) ->
                    return callback new HttpError 500 if err
                    callback null, desc

            when 'service'
                switch action
                    when 'description'
                        # Service descriptions are static XML files.
                        fs.readFile(
                            __dirname + '/services/' + serviceType + '.xml'
                            'utf8'
                            (err, file) ->
                                return callback new HttpError 500 if err
                                callback null, file
                        )
                    when 'control'
                        if req.method isnt 'POST' or not req.headers.soapaction?
                            return callback new HttpError 405
                        data = ''
                        req.on 'data', (chunk) ->
                            data += chunk
                        req.on 'end', =>
                            # `soapaction` header is like
                            # `urn:schemas-upnp-org:service:serviceType:v#actionName`
                            serviceAction = /:\d#(\w+)"$/.exec(
                                req.headers.soapaction
                            )[1]
                            console.info "#{serviceAction} on #{serviceType}
 invoked by #{req.client.remoteAddress}."
                            @services[serviceType].action(
                                serviceAction
                                data
                                (err, soapResponse) ->
                                    callback err, soapResponse, ext: null
                            )
                    when 'event'
                        console.info "#{req.method} on #{serviceType} sent
 by #{req.client.remoteAddress}."
                        {sid, nt, timeout} = req.headers
                        cbUrls = req.headers.callback
                        console.log sid, nt, timeout, cbUrls
                        switch req.method
                            when 'SUBSCRIBE'
                                # See Device specification for details on errors.
                                if nt? and cbUrls?
                                    unless /<http/.test cbUrls
                                        return callback new HttpError 412
                                    @services[serviceType].subscribe(
                                        cbUrls.slice(1, -1)
                                        timeout
                                        (err, respHeaders) ->
                                            callback err, null, respHeaders
                                    )
                                else if sid? and not (nt? or cbUrls?)
                                    @services[serviceType].renew sid, timeout, ->
                                        (err, respHeaders) ->
                                            callback err, null, respHeaders
                                else
                                    return callback new HttpError 400
                            when 'UNSUBSCRIBE'
                                unless sid?
                                    return callback new HttpError 412
                                if nt? or cbUrls?
                                    return callback new HttpError 400
                                @services[serviceType].unsubscribe sid
                                # Response is simply "200 OK".
                                callback()

                    else
                        callback new HttpError 404
            else
                callback new HttpError 404


    # Get internal IP and pass IP/port to callback. Needed for SSDP messages.
    listen = (callback) ->
        helpers.getNetworkIP (err, address) ->
            return callback err if err
            server.listen (err) ->
                port = server.address().port
                console.info "Web server listening on http://#{address}:#{port}."
                callback err, { address: address, port: port }

    listen (err, serverInfo) ->
        callback err, serverInfo
