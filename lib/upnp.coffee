devices =
    MediaServer: require "./devices/MediaServer"

upnp =
    createDevice: (name, type) -> new devices[type](name)

module.exports = upnp
