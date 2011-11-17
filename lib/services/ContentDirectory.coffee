# Implements ContentDirectory:1
# http://upnp.org/specs/av/av1/

Service = require './Service'

class ContentDirectroy extends Service

    constructor: (@device, type) ->
        super device, type
        @type = 'ContentDirectory'
        @stateVariables =
            'SystemUpdateID': 0
            'ContainerUpdateIDs': ''

    GetSearchCapabilities: (options, callback) ->
        @buildSoapResponse(
            'GetSearchCapabilities'
            SearchCaps: ''
            (err, resp) ->
                callback err, resp
        )

    GetSortCapabilities: (options, callback) ->
        @buildSoapResponse(
            'GetSortCapabilities'
            SortCaps: '*'
            (err, resp) ->
                callback err, resp
        )

    GetSystemUpdateID: (options, callback) ->
        @getStateVar 'SystemUpdateID', 'Id', (err, resp) -> callback err, resp

    Search: @optionalAction
    CreateObject: @optionalAction
    DestroyObject: @optionalAction
    UpdateObject: @optionalAction
    ImportResource: @optionalAction
    ExportResource: @optionalAction
    StopTransferResource: @optionalAction
    GetTransferProgress: @optionalAction
    
module.exports = ConnectionManager
