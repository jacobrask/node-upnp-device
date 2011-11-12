# HTTP helpers. If they depend on Device state they will be exported and
# added as Device prototypes.

fs   = require 'fs'
http = require 'http'
url  = require 'url'

helpers = require './helpers'
httpu   = require './httpu'

# `@` is bound to Device for functions depending on Device state.
exports.start = (callback) ->

    server = http.createServer (req, res) =>
        helpers.debug "#{req.url} requested by #{req.client.remoteAddress}"
        handler req, (err, data) =>
            if err?
                # On error, `data` is an error code. Very rudimentary error
                # handling, as it is not intended for humans anyway.
                res.writeHead data, 'CONTENT-TYPE': 'text/plain'
                res.write "#{data} - #{err.message}"
            else
                # TODO: Move to `httpu` module to share SSDP and SOAP header
                # generation logic.
                res.writeHead 200,
                    'CONTENT-TYPE': 'text/xml; charset="utf-8"'
                    'CONTENT-LENGTH': Buffer.byteLength(data)
                    'EXT': ''
                    'SERVER': httpu.makeServerString @name
                res.write data
            res.end()

    handler = (req, callback) =>
        # URLs are like `/device|service/action/[serviceType]`.
        [category, action, serviceType] = req.url.split('/')[1..]
        switch category
            when 'device'
                if action isnt 'description'
                    return callback new Error('Not Found'), 404
                @buildDescription (err, desc) ->
                    return callback err, 500 if err
                    callback null, desc

            when 'service'
                switch action
                    when 'description'
                        # Service descriptions are static XML files.
                        fs.readFile(
                            __dirname + '/services/' + serviceType + '.xml'
                            'utf8'
                            (err, file) ->
                                return callback err, 500 if err
                                callback null, file
                        )
                    when 'control'
                        if req.method isnt 'POST' or not req.headers.soapaction?
                            callback new Error('Method Not Allowed'), 405
                        data = ''
                        req.on 'data', (chunk) ->
                            data += chunk
                        req.on 'end', =>
                            # `soapaction` header is like
                            # `urn:schemas-upnp-org:service:serviceType:v#actionName`
                            serviceAction = /:\d#(\w+)"$/.exec(req.headers.soapaction)[1]
                            @services[serviceType].action(
                                serviceAction
                                data
                                (err, soapResponse) ->
                                    callback err, soapResponse
                            )
            else
                callback new Error('File not found'), 404

    # Get internal IP and pass IP/port to callback. Needed for SSDP messages.
    listen = (callback) ->
        helpers.getNetworkIP (err, address) ->
            return callback err if err
            server.listen (err) ->
                port = server.address().port
                helpers.debug "Web server listening on http://#{address}:#{port}"
                callback err, { address: address, port: port }

    listen (err, serverInfo) ->
        callback err, serverInfo
