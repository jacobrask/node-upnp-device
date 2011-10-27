dgram = require 'dgram'

exports.start = (callback) ->
    server = dgram.createSocket 'udp4'
    server.send(message, 0, message.length, 1900, "239.255.255.250")
    server.close()
    callback()
