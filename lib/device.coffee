extend = require('./helpers').extend
xml = require 'xml'

# merged with configs passed when loading module
configDefaults =
    device:
        schema:
            prefix: 'urn:schemas-upnp-org:device'
    uuid: '4061a4c0-0020-11e1-be50-0800200c9a66'

exports.buildDescription = (response, config, callback) ->
    extend config, configDefaults

    # generate namespace string
    genNS = (callback) ->
        ns = [
            config['device']['schema']['prefix']
            config['device']['version'].split('.')[0]
            config['device']['version'].split('.')[1]
        ]
        ns = ns.join('-')
        callback ns
    
    # build spec version element
    buildSpecVersion = (callback) ->
        major = config['device']['version'].split('.')[0]
        minor = config['device']['version'].split('.')[1]
        specVersion = [
            { major: major }
            { minor: minor }
        ]
        callback specVersion

    # build device element
    buildDevice = (callback) ->
        type = [
            config['device']['schema']['prefix']
            config['device']['type']
            config['device']['version'].split('.')[0]
        ]
        type = type.join(':')
        name = config['app']['name']
        url = config['app']['url']
        version = config['app']['version']
        udn = 'uuid:' + config['uuid']
        d = []
        d.push { deviceType: type }
        d.push { friendlyName: name }
        d.push { manufacturer: name }
        d.push { modelName: name + ' Media Server' }
        d.push { UDN: udn }
        callback d

    genNS (xmlns) ->
        root = xml.Element { _attr: { xmlns: xmlns } }
        desc = xml { root: root }, { stream: true }
        desc.pipe response

        process.nextTick ->
            buildSpecVersion (specVersionEl) ->
                root.push { specVersion: specVersionEl }
                buildDevice (deviceEl) ->
                    root.push { device: deviceEl }
                    root.close()
                    callback()
