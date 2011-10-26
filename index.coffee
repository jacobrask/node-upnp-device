# npm modules
xml = require 'xml'

# internal modules
device = require './lib/upnp-device'
xmlServer = require './lib/xml-server'

xmlServer.start (response) ->
    # get device schema / xml namespace
    device.buildSchema '1.0', (root) ->
        desc = xml { root: root }, { stream: true }
        desc.pipe response

        process.nextTick ->
            device.buildSpecVersion '1.0', (specVersion) ->
                root.push { specVersion: specVersion }
                specVersion.close()
                root.close()
