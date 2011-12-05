# Implements [ContentDirectory:1] [1].
#
# [1]: http://upnp.org/specs/av/av1/

redis = require 'redis'

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

        @startDb()

    actionHandler: (action, options, callback) ->
        # Optional actions not (yet) implemented.
        optionalActions = [ 'Search', 'CreateObject', 'DestroyObject',
                            'UpdateObject', 'ImportResource', 'ExportResource',
                            'StopTransferResource', 'GetTransferProgress' ]
        return @optionalAction callback if action in optionalActions

        # State variable actions and associated XML element names.
        stateActions =
            GetSearchCapabilities: 'SearchCaps'
            GetSortCapabilities: 'SortCaps'
            GetSystemUpdateID: 'Id'
        return @getStateVar action, stateActions[action], callback if action of stateActions

        switch action
            when 'Browse'
                browseCallback = (err, resp) =>
                    return @buildSoapError err, callback if err?
                    callback null, resp

                switch options?.BrowseFlag
                    when 'BrowseMetadata'
                        @browseMetadata options, browseCallback
                    when 'BrowseDirectChildren'
                        @browseChildren options, browseCallback
                    else
                        browseCallback new SoapError 402
            else
                @buildSoapError new SoapError(401), callback

    startDb: ->
        @redis = redis.createClient()
        @redis.on 'error', (err) -> throw err
        # Flush database. FIXME.
        @redis.flushdb()

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

module.exports = ContentDirectory
