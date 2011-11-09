ssdp = require './ssdp'
xmlServer = require './xml-server'

class Device

    constructor: (@name) ->
        unless @name
            new Error "Please supply a name for your UPnP Device."

    start: ->
        server = xmlServer.createServer @type, @name
        xmlServer.listen server, (err, httpServer) =>
            ssdp.announce { type: @type, name: @name }, httpServer
            ssdp.listen { type: @type, name: @name }, httpServer
            callback err

exports.Device = Device
exports.MediaServer = require './devices/MediaServer'
