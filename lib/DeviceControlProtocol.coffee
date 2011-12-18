# Base class for Device and Service. Properties and functionality as
# specified in [UPnP Device Control Protocol] [1].
#
# [1]: http://upnp.org/index.php/sdcps-and-certification/standards/sdcps/

{EventEmitter} = require 'events'
url = require 'url'

class DeviceControlProtocol extends EventEmitter

    constructor: ->

    schema: { prefix: 'urn:schemas-upnp-org', version: '1.0' }
    upnp: { version: '1.0' }

    # Make namespace string for services, devices, events, etc.
    makeNS: (category, suffix = '') ->
        category ?= if @device? then 'service' else 'device'
        @schema.prefix + ':' + [
            category
            @schema.version.split('.')[0]
            @schema.version.split('.')[1] ].join('-') + suffix

    # Make device/service type string for descriptions and SSDP messages.
    makeType: ->
        category ?= if @device? then 'service' else 'device'
        [ @schema.prefix
            category
            @type
            @version or @device.version
        ].join ':'


    # URL generation.
    makeUrl: (path) ->
        url.format
            protocol: 'http'
            hostname: @address
            port: @httpPort
            pathname: path

    makeDescriptionUrl:  -> @makeUrl '/device/description'
    makeContentUrl: (id) -> @makeUrl "/resource/#{id}"


module.exports = DeviceControlProtocol
