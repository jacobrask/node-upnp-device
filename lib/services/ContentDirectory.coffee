# Implements [ContentDirectory:1] [1].
#
# [1]: http://upnp.org/specs/av/av1/

Service = require './Service'
{SoapError} = require '../xml'

# Capitalized properties are native UPnP control actions.
class ContentDirectory extends Service

    constructor: (@device) ->
        super
        @type = 'ContentDirectory'
        # If a var is evented, it is included in notifications to subscribers.
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


    browseChildren: (options, callback) ->
        id    = parseInt(options?.ObjectID or 0)
        start = parseInt(options?.StartingIndex or 0)
        max   = parseInt(options?.RequestedCount or 0)

        @device.fetchChildren id, (err, objects) =>
            return callback err if err
            # Limit matches. Should be done before fetch instead.
            end = if max is 0 then objects.length - 1 else start + max
            matches = objects[start..end]
            @device.getUpdateId id, (err, updateId) =>
                @buildSoapResponse(
                    'Browse'
                    NumberReturned: matches.length
                    TotalMatches: objects.length
                    Result: @buildDidl matches
                    UpdateID: updateId
                    callback
                )

    browseMetadata: (options, callback) ->
        id = parseInt(options?.ObjectID or 0)
        @device.fetchObject id, (err, object) =>
            return callback err if err
            @device.getUpdateId id, (err, updateId) =>
                @buildSoapResponse(
                    'Browse'
                    NumberReturned: 1
                    TotalMatches: 1
                    Result: @buildDidl [ object ]
                    UpdateID: updateId
                    callback
                )

    Browse: (options, callback) ->
        browseCallback = (err, resp) =>
            if err
                console.warn "Browse action caused #{err.message}."
                @buildSoapError err, callback
            else
                callback null, resp

        switch options?.BrowseFlag
            when 'BrowseMetadata'
                @browseMetadata options, browseCallback
            when 'BrowseDirectChildren'
                @browseChildren options, browseCallback
            else
                browseCallback new SoapError 402

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
