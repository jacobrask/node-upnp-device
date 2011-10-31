http = require 'http'
fs = require 'fs'
url = require 'url'
device = require './device'

exports.start = (config, callback) ->
    port = config['network']['http']['port']
    address = config['network']['http']['address']

    server = http.createServer (request, response) ->
        # url formats:
        # /device/description
        # /service/(description|control|event)/serviceType
        path = url.parse(request.url).pathname.split('/')
        reqType = path[1]
        action = path[2]
        serviceType = path[3]

        if reqType in ['device', 'service']
            response.writeHead 200, 'Content-Type': 'text/xml'
            # service descriptions are static files
            if reqType is 'service' and action is 'description'
                fs.readFile __dirname + '/services/' + serviceType + '.xml', (err, file) ->
                    throw err if err
                    response.write file
                    response.end()
            else
                response.write '<?xml version="1.0" encoding="utf-8"?>\n'
                if reqType is 'device'
                    response.write device.buildDescription config
                response.end()
        else
            response.writeHead 404, 'Content-Type': 'text/plain'
            response.write '404 Not found'
            response.end()

    server.listen port, address, ->
        callback null, "SOAP server started at #{address}:#{port}"
