# Implements [ContentDirectory:1] [1].
#
# [1]: http://upnp.org/specs/av/av1/

async = require 'async'
fs    = require 'fs'
log   = new (require 'log')
mime  = require 'mime'
redis = require 'redis'
mime.define 'audio/flac': ['flac']

Service = require './Service'
{SoapError} = require '../errors'

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
                    callback null, (if err? then @buildSoapError(err) else resp)

                switch options?.BrowseFlag
                    when 'BrowseMetadata'
                        @browseMetadata options, browseCallback
                    when 'BrowseDirectChildren'
                        @browseChildren options, browseCallback
                    else
                        browseCallback new SoapError 402
            else
                callback null, @buildSoapError new SoapError(401)

    startDb: ->
        # Should probably create a private redis process here instead.
        @redis = redis.createClient()
        @redis.on 'error', (err) -> throw err
        @redis.select 9
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

        @fetchChildren id, (err, objects) =>
            return callback err if err?
            # Limit matches. Should be done before fetch instead.
            end = if max is 0 then objects.length - 1 else start + max
            matches = objects[start..end]
            @getUpdateId id, (err, updateId) =>
                callback err, @buildSoapResponse 'Browse',
                    NumberReturned: matches.length
                    TotalMatches: objects.length
                    Result: @buildDidl matches
                    UpdateID: updateId

    browseMetadata: (options, callback) ->
        id = parseInt(options?.ObjectID or 0)
        @fetchObject id, (err, object) =>
            return callback err if err?
            @getUpdateId id, (err, updateId) =>
                callback err, @buildSoapResponse 'Browse',
                    NumberReturned: 1
                    TotalMatches: 1
                    Result: @buildDidl [ object ]
                    UpdateID: updateId


    addMedia: (parentID, media, callback) ->
        unless media.class? and media.title?
            return callback new Error 'Missing required property.'

        buildObject = (object, callback) =>
            object.type = /object\.(\w+)/.exec(object.class)[1]
            if object.type is 'item' and object.location?
                object.contenttype ?= mime.lookup(object.location)
                @addContentType object.contenttype

            fs.stat object.location, (err, stats) ->
                object.filesize = stats?.size or 0
                callback null, object

        # Insert root element and then iterate through its children and insert them.
        buildObject media, (err, object) =>
            @insertContent parentID, object, callback


    # Add object to Redis data store.
    insertContent: (parentID, object, callback) ->
        # Increment and return Object ID.
        @redis.incr 'nextid', (err, id) =>
            # Add Object ID to parent containers's child set.
            @redis.sadd "#{parentID}:children", id
            # Increment each time container (or parent container) is modified.
            @redis.incr "#{if object.type is 'container' then id else parentID}:updateid"
            # Add ID's to item data structure and insert into data store.
            object.id = id
            object.parentid = parentID
            @redis.hmset "#{id}", object
            callback err, id

    # Remove object with @id and all its children.
    removeContent: (id, callback) ->
        @redis.smembers "#{id}:children", (err, childIds) =>
            return callback new SoapError 501 if err?
            for childId in childIds
                @redis.del "#{childId}"
            @redis.del [ "#{id}", "#{id}:children", "#{id}:updateid" ]
            # Return value shouldn't matter to client, at least for now.
            # If the smembers call worked at least we know the db is working.
            callback null

    # Get metadata of all direct children of object with @id.
    fetchChildren: (id, callback) ->
        @redis.smembers "#{id}:children", (err, childIds) =>
            return callback new SoapError 501 if err?
            return callback new SoapError 701 unless childIds.length
            async.concat(
                childIds
                (cId, callback) => @redis.hgetall "#{cId}", callback
                (err, results) ->
                    callback err, results
            )

    # Get metadata of object with @id.
    fetchObject: (id, callback) ->
        @redis.hgetall "#{id}", (err, object) ->
            return callback new SoapError 501 if err?
            return callback new SoapError 701 unless Object.keys(object).length > 0
            callback null, object

    getUpdateId: (id, callback) ->
        getId = (id, callback) =>
            @redis.get "#{id}:updateid", (err, updateId) ->
                return callback new SoapError 501 if err?
                callback null, updateId

        if id is 0
            return callback null, @stateVars.SystemUpdateID.value
        else
            @redis.exists "#{id}:updateid", (err, exists) =>
                # If this ID doesn't have an updateid key, get parent's updateid.
                if exists is 1
                    getId id, callback
                else
                    @redis.hget "#{id}", 'parentid', (err, parentId) =>
                        getId parentId, callback

module.exports = ContentDirectory
