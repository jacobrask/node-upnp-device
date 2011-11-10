fs = require 'fs'
uuid = require 'node-uuid'

config =
    ssdp: do ->
        port: do -> 1900
        address: do -> '239.255.255.250'
        timeout: do -> 1800

# persist UUID across restarts
try
    config.uuid = do -> fs.readFileSync("#{__dirname}/../upnp-uuid", 'utf8')
catch error
    config.uuid = do -> 'uuid:' + uuid()
    fs.writeFileSync("#{__dirname}/../upnp-uuid", config.uuid)

module.exports = config
