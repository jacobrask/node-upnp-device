http = require 'http'
url = require 'url'
device = require './device'

exports.start = (config, callback) ->
    port = config['network']['http']['port']
    address = config['network']['http']['address']

    server = http.createServer (request, response) ->
        path = url.parse(request.url).pathname.split('/')
        reqType = path[1]
       
        if reqType is 'device'
            response.writeHead 200, 'Content-Type': 'text/xml'
            response.write '<?xml version="1.0"?>\n'
            response.write device.buildDescription config
            response.end()
        else
            response.writeHead 404, 'Content-Type': 'text/plain'
            response.write '404 Not found'
            response.end()

    server.listen port, address, ->
        callback null, "SOAP server started at #{address}:#{port}"
