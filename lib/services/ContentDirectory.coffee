# Implements ContentDirectory:1
# http://upnp.org/specs/av/av1/

Service = require './Service'

class ContentDirectory extends Service

    constructor: (@device) ->
        super
        @type = 'ContentDirectory'
        @stateVars =
            SystemUpdateID:
                value: 0
                evented: true
            ContainerUpdateIDs:
                value: ''
                evented: true
            SearchCapabilities:
                value: ''
                evented: false
            SortCapabilities:
                value: '*'
                evented: false

    addContentType: (type) ->
        @contentTypes ?= []
        unless type in @contentTypes
            @contentTypes.push type
            @emit 'newContentType'

    Browse: (options, callback) ->
        {
            ObjectID: id
            BrowseFlag: flag
            Filter: filter
            StartingIndex: start
            RequestedCount: num
            SortCriteria: sort
        } = options

        @device.fetchChildren id, (err, object) ->
            console.log object

    GetSearchCapabilities: (options, callback) ->
        @getStateVar 'SearchCapabilities', 'SearchCaps', callback

    GetSortCapabilities: (options, callback) ->
        @getStateVar 'SortCapabilities', 'SortCaps', callback

    GetSystemUpdateID: (options, callback) ->
        @getStateVar 'SystemUpdateID', 'Id', callback

    Search: @optionalAction
    CreateObject: @optionalAction
    DestroyObject: @optionalAction
    UpdateObject: @optionalAction
    ImportResource: @optionalAction
    ExportResource: @optionalAction
    StopTransferResource: @optionalAction
    GetTransferProgress: @optionalAction

module.exports = ContentDirectory
