fs = require 'fs'
uuid = require 'node-uuid'

config =
    schemaPrefix: do -> 'urn:schemas-upnp-org'
    versions: do ->
        schema: do -> '1.0'
        upnp: do -> '1.0'
    devices: do ->
        MediaServer: do ->
            version: do -> 1
            services: do -> [ 'ConnectionManager', 'ContentDirectory' ]
    ssdp: do ->
        port: do -> 1900
        address: do -> '239.255.255.250'
        timeout: do -> 1800

# persist UUID across restarts
try
    config.uuid = do -> 'uuid:' + fs.readFileSync("#{__dirname}/../upnp-uuid", 'utf8')
catch error
    config.uuid = do -> 'uuid:' + uuid()
    fs.writeFileSync("#{__dirname}/../upnp-uuid", config.uuid)

module.exports = config
