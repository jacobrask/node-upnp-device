# npm modules
xml = require 'xml'

# internal modules
device = require './lib/upnp-device'
xmlServer = require './lib/xml-server'

config =
    version: '1.0'
    type: 'MediaServer'

xmlServer.start (response) ->
    # get device schema / xml namespace
    device.buildSchema config, (root) ->
        desc = xml { root: root }, { stream: true }
        desc.pipe response

        process.nextTick ->
            device.buildSpecVersion config, (specVersion) ->
                root.push { specVersion: specVersion }
                specVersion.close()
                root.close()
