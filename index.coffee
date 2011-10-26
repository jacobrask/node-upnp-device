http = require 'http'
xml = require 'xml'

server = http.createServer (req, res) ->
    res.writeHead 200, 'Content-Type': 'text/xml'
    res.write '<?xml version="1.0" encoding="utf-8"?>\n'

    deviceSchema '1.0', (root) ->
        desc = xml({ root: root }, { stream: true })
        desc.pipe res

        process.nextTick ->
            deviceSpecVersion '1.0', (spec) ->
                root.push { specVersion: spec }
                spec.close()
                root.close()

deviceSchema = (version, callback) ->
    major = version.split('.')[0]
    minor = version.split('.')[1]
    schema = 'urn:schemas-upnp-org:device-' + major + '-' + minor
    callback xml.Element { _attr: { xmlns: schema } }

deviceSpecVersion = (version, callback) ->
    major = version.split('.')[0]
    minor = version.split('.')[1]
    callback xml.Element [ { major: major }, { minor: minor } ]

server.listen(3000)
