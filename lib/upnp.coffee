# Currently implemented devices.
deviceList = [ 'MediaServer' ]

# Require device files. They each export a constructor function.
Devices = {}
for deviceType in deviceList
    Devices[deviceType] = require "./devices/#{deviceType}"

exports.createDevice = (type, name, callback) ->
    unless type in deviceList
        err = new Error "UPnP device of type #{type} is not yet implemented."
        console.error err.message
        callback err

    # Constructor is asynchronous and returns itself.
    new Devices[type] name, (err, device) ->
        callback err, device
