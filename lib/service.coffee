# generate service type string
makeServiceType = (type, config, version = 1) ->
    typeSchema = [
        config.specs.upnp.prefix
        'service'
        type
        version
    ]
    typeSchema.join ':'

buildServiceList = (config) ->

    buildService = (serviceType) ->
        [
            { serviceType: makeServiceType(serviceType, config) }
            { serviceId: 'urn:upnp-org:serviceId:' + serviceType }
            { SCPDURL: '/service/description/' + serviceType }
            { controlURL: '/service/control/' + serviceType }
            { eventSubURL: '/service/event/' + serviceType }
        ]

    serviceList = []
    for serviceType in config.services
        serviceList.push { service: buildService(serviceType) }
    
    [ { serviceType: 'foo' } ]
    serviceList

exports.makeServiceType = makeServiceType
exports.buildServiceList = buildServiceList
