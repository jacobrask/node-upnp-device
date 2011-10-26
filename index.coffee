# npm modules
http = require 'http'
xml = require 'xml'

# internal modules
device = require './lib/upnp-device'

server = http.createServer (req, res) ->
    res.writeHead 200, 'Content-Type': 'text/xml'
    res.write '<?xml version="1.0" encoding="utf-8"?>\n'

    # get device schema / xml namespace
    device.buildSchema '1.0', (root) ->
        desc = xml({ root: root }, { stream: true })
        desc.pipe res

        process.nextTick ->
            device.buildSpecVersion '1.0', (specVersion) ->
                root.push { specVersion: specVersion }
                specVersion.close()
                root.close()

server.listen(3000)
