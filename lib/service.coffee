buildServiceList = (config) ->
    # generate service type string
    makeServiceType = (type, version = 1) ->
        typeSchema = [
            config.specs.upnp.prefix
            'service'
            type
            version
        ]
        typeSchema.join ':'

    buildService = (serviceType) ->
        [
            { serviceType: makeServiceType(serviceType) }
            { serviceId: 'urn:upnp-org:serviceId:' + serviceType }
            { SCPDURL: '/service/description/' + serviceType }
            { controlURL: '/service/control/' + serviceType }
            { eventSubURL: '/service/event/' + serviceType }
        ]

    serviceList = []
    for serviceType in config.services
        serviceList.push { service: buildService(serviceType) }
    
    console.log serviceList
    [ { serviceType: 'foo' } ]
    serviceList

exports.buildServiceList = buildServiceList
