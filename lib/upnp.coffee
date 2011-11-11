# Currently implemented devices
deviceList = [ 'MediaServer' ]

# Require devices
devices = {}
for deviceType in deviceList
    devices[deviceType] = require "./devices/#{deviceType}"

exports.createDevice = (type, name, callback) ->
    unless type in deviceList
        callback new Error "UPnP device of type #{type} is not yet implemented."

    callback null, new devices[type](name)
