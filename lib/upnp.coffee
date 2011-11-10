# Currently implemented devices
deviceList = [ 'MediaServer' ]

devices = {}
for deviceType in deviceList
    # device classes are in devices/<DeviceType>.coffee
    devices[deviceType] = require "./devices/#{deviceType}"

exports.createDevice = (type, name) ->
    if not type in deviceList
        return new Error "UPnP device of type #{type} is not yet implemented."

    return new devices[type](name)
