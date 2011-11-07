{exec} = require 'child_process'

debug = exports.debug =
    if process.env.NODE_DEBUG && /upnp-device/.test process.env.NODE_DEBUG
        (args...) -> console.error 'UPNP:', args...
    else
        ->

exports.getNetworkIP = (callback) ->
    exec 'ifconfig', (err, stdout, sterr) ->
        if process.platform is 'darwin'
            filterRE = /\binet\s+([^\s]+)/g
        else
            filterRE = /\binet\b[^:]+:\s*([^\s]+)/g
        # extract IPs
        matches = stdout.match(filterRE)

        # filter out localhost ips
        callback err, matches
            .map((match) -> match.replace filterRE, '$1')
            .filter((match) -> !/^(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test match)[0]
