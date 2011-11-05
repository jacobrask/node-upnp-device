config = require './config'
xmlServer = require './xml-server'
ssdp = require './ssdp'

upnp =
    createDevice: (deviceName, deviceType, callback) ->
        dev =
            name: deviceName
            type: deviceType
        unless config.devices[dev.type]
            return callback new Error "The type you specified does not exist or is not implemented in upnp-device yet."
        unless dev.name?
            return callback new Error "Please supply a name for your UPnP Device."
        
        server = xmlServer.createServer dev.type, dev.name
        xmlServer.listen server, (err, httpServer) ->
            ssdp.announce dev, httpServer
            ssdp.listen dev, httpServer
            callback err, "#{deviceType} device successfully started and announced."

module.exports = upnp
