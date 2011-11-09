# Implements ConnectionManager:1
# http://upnp.org/specs/av/av1/

class ConnectionManager extends (require './Service')
    constructor: (@type) ->
        super type

    GetProtocolInfo:
        console.log

module.exports = ConnectionManager
