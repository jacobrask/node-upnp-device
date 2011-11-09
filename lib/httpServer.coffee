fs   = require 'fs'
http = require 'http'
url  = require 'url'

helpers = require './helpers'

class httpServer
    constructor: (@device) ->
        @server = http.createServer(@listener)

    listener: (req, res) =>
        helpers.debug "#{req.url} served to #{req.client.remoteAddress}"

        @handler req.url, (err, data) ->
            if err?
                res.writeHead data, 'Content-Type': 'text/plain'
                res.write "#{data} - #{err.message}"
            else
                res.writeHead 200,
                    'Content-Type': 'text/xml'
                    'Content-Length': Buffer.byteLength(data)
                res.write data
            res.end()

    handler: (path, callback) ->
        [foo, category, action, type] = path.split('/')
        console.log path
        switch category
            when 'device'
                if action isnt 'description'
                    return callback new Error('File not found'), 404
                body = '<?xml version="1.0" encoding="utf-8"?>\n'
                body += @device.buildDescription()
                callback null, body

            when 'service'
                switch action
                    when 'description'
                        # service descriptions are static XML files
                        fs.readFile @_makeServicePath(type), 'utf8', (err, file) ->
                            return callback err, 500 if err
                            callback null, file
                    when 'control'
                        if req.headers.soapaction? and req.method == 'POST'
                            data = ''
                            req.on 'data', (chunk) ->
                                data += chunk
                            req.on 'end', ->

                                console.log /#(\w+)/.exec(req.headers.soapaction)[1] # service action
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

    _makeServicePath: (serviceType) ->
        __dirname + '/services/' + serviceType + '.xml'

exports.createServer = (device) -> new httpServer(device)
