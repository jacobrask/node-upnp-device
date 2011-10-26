http = require 'http'

exports.start = (callback) ->
    http.createServer (request, response) ->
        response.writeHead 200,
            'Content-Type': 'text/xml'
        response.write '<?xml version="1.0" encoding="utf-8"?>\n'
        callback(response)
    .listen 3000
