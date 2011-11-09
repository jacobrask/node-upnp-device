fs   = require 'fs'
http = require 'http'
url  = require 'url'

helpers = require './helpers'

createServer = exports.createServer = (device) ->
    http.createServer (req, res) ->
        helpers.debug "#{req.url} served to #{req.client.remoteAddress}"

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
            # service descriptions are static XML files
            if isServiceReq(req) and getReqAction(req) is 'description'
                fs.readFile makeServicePath(getReqType(req)), 'utf8', (err, file) ->
                    throw err if err
                    serve file
            else if isServiceReq(req) and getReqAction(req) is 'control'
                if req.headers.soapaction and req.method == 'POST'
                    data = ''
                    req.on 'data', (chunk) ->
                        data += chunk
                    req.on 'end', ->
                        ###
                        soap.action(
                            getReqType(req) # service type
                            /#(\w+)/.exec(req.headers.soapaction)[1] # service action
                            data # xml
                        )
                        ###
            else if isDeviceReq(req)
                body = '<?xml version="1.0" encoding="utf-8"?>\n'
                body += device.buildDescription()
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
            helpers.debug "Web server listening on http://#{address}:#{port}"
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
