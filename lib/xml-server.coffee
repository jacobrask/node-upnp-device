http = require 'http'
url = require 'url'
device = require './device'

handle =
    '/description.xml': device.buildDescription

exports.start = (config, callback) ->
    http.createServer (request, response) ->
        path = url.parse(request.url).pathname
        if typeof handle[path] is 'function'
            response.writeHead 200,
                'Content-Type': 'text/xml'
            response.write '<?xml version="1.0" encoding="utf-8"?>\n'
            handle[path](response, config, callback)
        else
            response.writeHead 404,
                'Content-Type': 'text/plain'
            response.write '404 Not found'
            response.end()
            callback()

    .listen 3000
