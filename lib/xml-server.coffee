http = require 'http'
fs = require 'fs'
url = require 'url'
portscanner = require 'portscanner'
device = require './device'
helpers = require './helpers'
debug = helpers.debug

createServer = exports.createServer = (deviceType, deviceName) ->
    http.createServer (req, res) ->
        debug "#{req.url} served to #{req.client.remoteAddress}"

        serve = (body) ->
            res.writeHead 200,
                'Content-Type': 'text/xml'
                'Content-Length': Buffer.byteLength(body)
            res.write body
            res.end()

        error = (code) ->
            res.writeHead code,
                'Content-Type': 'text/plain'
            res.write "404 Not Found"
            res.end()

        if isServiceReq(req) or isDeviceReq(req)
            if isServiceReq(req) and getReqAction(req) is 'description'
                # service descriptions are static XML files
                fs.readFile makeServicePath(getReqType(req)), (err, file) ->
                    throw err if err
                    serve file.toString('utf8', 0, file.length)
            else if isDeviceReq(req)
                body = '<?xml version="1.0" encoding="utf-8"?>\n'
                body += device.buildDescription deviceType, deviceName
                serve(body)
            else
                error(404)
        else
            error(404)
        

# find a suitable IP/port and start listening on server
listen = exports.listen = (server, callback) ->
    helpers.getNetworkIP (err, address) ->
        return callback err if err
        server.listen (err) ->
            port = server.address().port
            debug "Web server listening on http://#{address}:#{port}"
            callback err, { address: address, port: port }

# handle requests in various ways
parseReq = (req) ->
    # url formats:
    # /device/description
    # /service/(description|control|event)/serviceType
    path = url.parse(req.url).pathname.split('/')
    {
        category: path[1]
        action: path[2]
        type: path[3]
    }
getReqCategory = (req) -> parseReq(req).category
getReqAction = (req) -> parseReq(req).action
getReqType = (req) -> parseReq(req).type

isDeviceReq = (req) -> getReqCategory(req) is 'device'
isServiceReq = (req) -> getReqCategory(req) is 'service'

makeServicePath = (serviceType) ->
    __dirname + '/services/' + serviceType + '.xml'
