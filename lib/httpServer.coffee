fs   = require 'fs'
http = require 'http'
url  = require 'url'

helpers = require './helpers'

class HttpServer
    constructor: (@device) ->
        @server = http.createServer(@listener)

    listener: (req, res) =>
        helpers.debug "#{req.url} requested by #{req.client.remoteAddress}"
        @handler req, (err, data) =>
            if err?
                res.writeHead data, 'CONTENT-TYPE': 'text/plain'
                res.write "#{data} - #{err.message}"
            else
                res.writeHead 200,
                    'CONTENT-TYPE': 'text/xml; charset="utf-8"'
                    'CONTENT-LENGTH': Buffer.byteLength(data)
                    'EXT': ''
                    'SERVER': @device.makeServerString()
                res.write data
            res.end()

    handler: (req, callback) ->
        [foo, category, action, type] = req.url.split('/')
        switch category
            when 'device'
                if action isnt 'description'
                    return callback new Error('Not Found'), 404
                @device.buildDescription (err, desc) ->
                    return callback err, 500 if err
                    callback null, desc

            when 'service'
                switch action
                    when 'description'
                        # service descriptions are static XML files
                        fs.readFile @makeServicePath(type), 'utf8', (err, file) ->
                            return callback err, 500 if err
                            callback null, file
                    when 'control'
                        if req.method isnt 'POST' or not req.headers.soapaction?
                            callback new Error('Method Not Allowed'), 405
                        data = ''
                        req.on 'data', (chunk) ->
                            data += chunk
                        req.on 'end', =>
                            [foo, serviceType, serviceAction] = ///
                                (\w+) # service type
                                :\d#
                                (\w+) # service action
                                "$
                            ///.exec(req.headers.soapaction)
                            @device.services[serviceType].action serviceAction, data, (err, soapResponse) ->
                                callback err, soapResponse
            else
                callback new Error('File not found'), 404


    # find internal IP and start listening on server
    listen: (callback) ->
        helpers.getNetworkIP (err, address) =>
            return callback err if err
            @server.listen (err) =>
                port = @server.address().port
                helpers.debug "Web server listening on http://#{address}:#{port}"
                callback err, { address: address, port: port }

    makeServicePath: (serviceType) ->
        __dirname + '/services/' + serviceType + '.xml'

exports.createServer = (device) -> new HttpServer(device)
