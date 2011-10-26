# npm modules
xml = require 'xml'

# internal modules
device = require './lib/upnp-device'
xmlServer = require './lib/xml-server'

config =
    upnp_urn: 'urn:schemas-upnp-org'
    version: '1.0'
    type: 'MediaServer'

xmlServer.start (response) ->
    # get device schema / xml namespace
    device.buildNSURN config, (rootEl) ->
        desc = xml { root: rootEl }, { stream: true }
        desc.pipe response

        process.nextTick ->
            device.buildSpecVersion config, (specVersionEl) ->
                rootEl.push { specVersion: specVersionEl }
                specVersionEl.close()
                buildDeviceTree(config, rootEl)

    buildDeviceTree = (config, rootEl) ->
        device.buildDevice config, (deviceEl) ->
            rootEl.push { device: deviceEl }
            rootEl.close()
