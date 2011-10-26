# npm modules
xml = require 'xml'

# internal modules
device = require './lib/upnp-device'
xmlServer = require './lib/xml-server'

config =
    upnp_urn: 'urn:schemas-upnp-org'
    version: '1.0'
    type: 'MediaServer'
    uuid: '4061a4c0-0020-11e1-be50-0800200c9a66'
    app:
        name: 'Bragi'
        version: '0.0.1'
        url: 'http://'

xmlServer.start (response) ->
    # get device schema / xml namespace
    device.buildNSURN config, (xmlns) ->
        root = xml.Element { _attr: { xmlns: xmlns } }
        desc = xml { root: root }, { stream: true }
        desc.pipe response

        process.nextTick ->
            device.buildSpecVersion config, (specVersionXML) ->
                root.push { specVersion: specVersionXML }
                device.buildDevice config, (deviceXML) ->
                    root.push { device: deviceXML }
                    root.close()
