extend = (object, extenders...) ->
    return {} if not object?
    for other in extenders
        for own key, val of other
            if not object[key]? or typeof val isnt 'object'
                object[key] = val
            else
                object[key] = extend object[key], val
    object

exports.extend = extend

exports.getNetworkIP = (callback) ->
    ignoreRE = /^(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i
    exec = require('child_process').exec

    if process.platform is 'darwin'
        filterRE = /\binet\s+([^\s]+)/g
    else
        filterRE = /\binet\b[^:]+:\s*([^\s]+)/g
    exec 'ifconfig', (err, stdout, sterr) ->
        ips = []
        # extract IPs
        matches = stdout.match(filterRE)
        if matches
            # JS has no lookbehind REs, so we need a trick
            for match in matches
                ips.push match.replace filterRE, '$1'
            for ip in ips
                # filter BS
                unless ignoreRE.test ip
                    callback err, ip
        else
            callback err, null
