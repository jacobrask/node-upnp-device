ssdp = require './ssdp'
web = require './web'

class Device

    constructor: (@name) ->
        unless @name
            new Error "Please supply a name for your UPnP Device."
        @schema =
            prefix: 'urn:schemas-upnp-org'
            version: '1.0'
            upnpVersion: '1.0'
        @

    start: (callback) ->
        server = web.createServer @
        web.listen server, (err, httpServer) =>
            ssdp.announce @, httpServer
            ssdp.listen @, httpServer
            callback err, httpServer

exports.Device = Device

devices =
    MediaServer: require "./devices/MediaServer"

upnp =
    createDevice: (name, type) ->
        new devices[type](name)

module.exports = upnp
