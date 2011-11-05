uuid = require 'node-uuid'

config =
    schemaPrefix: do -> 'urn:schemas-upnp-org'
    uuid: do -> 'uuid:' + uuid()
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

module.exports = config
