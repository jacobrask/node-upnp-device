# Implements [MediaServer:1] [1].
#
# [1]: http://upnp.org/specs/av/av1/

async = require 'async'
fs    = require 'fs'
mime  = require 'mime'
redis = require 'redis'

Device = require('./Device')
{SoapError} = require '../xml'

class MediaServer extends Device

    constructor: (name, callback) ->
        super
        @type = 'MediaServer'
        @version = 1
        
        @services = {}
        @services.ContentDirectory  = new (require '../services/ContentDirectory')(@)
        @services.ConnectionManager = new (require '../services/ConnectionManager')(@)
        @redis = redis.createClient()
        @redis.on 'error', (err) ->
            throw err if err?
        # Flush database. FIXME.
        @redis.flushdb()

    addMedia: (parentID, media, callback) ->

        buildObject = (obj, parent, callback) ->
            # If an object has children, it's a container.
            if obj.children?
                buildContainer obj, callback
            else
                buildItem obj, parent, callback

        buildContainer = (obj, callback) ->
            cnt =
                class: 'object.container.'
            switch obj.type
                when 'musicalbum'
                    cnt.class +='album.musicAlbum'
                    cnt.title = obj.title or 'Untitled album'
                    cnt.creator = obj.creator
                when 'photoalbum'
                    cnt.class += 'album.photoAlbum'
                    cnt.title = obj.creator or 'Untitled album'
                when 'musicartist'
                    cnt.class += 'person.musicArtist'
                    cnt.title = obj.creator or 'Unknown artist'
                    cnt.creator = obj.creator or obj.title
                when 'musicgenre'
                    cnt.class += 'genre.musicGenre'
                    cnt.title = obj.title or 'Unknown genre'
                when 'moviegenre'
                    cnt.class += 'genre.movieGenre'
                    cnt.title = obj.title or 'Unknown genre'
                else
                    cnt.class += 'storageFolder'
                    cnt.title = obj.title or 'Folder'

            cnt.class = 'object.container'
            callback null, cnt

        buildItem = (obj, parent, callback) =>
            item =
                class: 'object.item'
                title: obj.title or 'Untitled'
                creator: obj.creator or parent.creator
                location: obj.location

            mimeType = mime.lookup(obj.location)
            @services.ContentDirectory.addContentType mimeType
            item.protocol = "http-get:*:#{mimeType}:*"

            # Try to figure out type from parent type.
            obj.type ?=
                switch parent?.type
                    when 'musicalbum' or'musicartist' or 'musicgenre'
                        'musictrack'
                    when 'photoalbum'
                        'photo'
                    when 'moviegenre'
                        'movie'
                    else
                        # Get the first part of the mime type as a last guess.
                        mimeType.split('/')[0]

            item.class +=
                switch obj.type
                    when 'audio'
                        'audioItem'
                    when 'audiobook'
                        '.audioItem.audioBook'
                    when 'musictrack'
                        '.audioItem.musicTrack'
                    when 'image'
                        '.imageItem'
                    when 'photo'
                        '.imageItem.photo'
                    when 'video'
                        '.videoItem'
                    when 'musicvideo'
                        '.videoItem.musicVideoClip'
                    when 'movie'
                        '.videoItem.movie'
                    when 'text'
                        '.textItem'
                    else
                        ''

            fs.stat obj.location, (err, stats) ->
                if err
                    console.warn "Error reading file #{obj.location}, setting file size to 0."
                    item.filesize = 0
                else
                    item.filesize = stats.size
                callback null, item
        
        # Insert root element and then iterate through its children and insert them.
        buildObject media, null, (err, object) =>
            @insertContent parentID, object, (err, id) =>
                # Call back with "top-most" ID as soon as we know it.
                callback err, id
                buildChildren id, media

        buildChildren = (parentID, parent) =>
            parent.children ?= []
            for child in parent.children
                buildObject child, parent, (err, object) =>
                    @insertContent parentID, object, (err, childID) ->
                        buildChildren childID, child

    # Add object to Redis data store.
    insertContent: (parentID, object, callback) ->
        type = /object\.(\w+)/.exec(object.class)[1]
        # Increment and return Object ID.
        @redis.incr "#{@uuid}:nextid", (err, id) =>
            # Add Object ID to parent containers's child set.
            @redis.sadd "#{@uuid}:#{parentID}:children", id
            # Increment each time container (or parent container) is modified.
            @redis.incr "#{@uuid}:#{if type is 'container' then id else parentID}:updateid"
            # Add ID's to item data structure and insert into data store.
            object.id = id
            object.parentid = parentID
            @redis.hmset "#{@uuid}:#{id}", object
            callback err, id

    # Remove object with @id and all its children.
    removeContent: (id, callback) ->
        @redis.smembers "#{@uuid}:#{id}:children", (err, childIds) =>
            return callback new SoapError 501 if err?
            for childId in childIds
                @redis.del "#{@uuid}:#{childId}"
            @redis.del [ "#{@uuid}:#{id}", "#{@uuid}:#{id}:children", "#{@uuid}:#{id}:updateid" ]
            # Return value shouldn't matter to client, at least for now.
            # If the smembers call worked at least we know the db is working.
            callback null

    # Get metadata of all direct children of object with @id.
    fetchChildren: (id, callback) ->
        @redis.smembers "#{@uuid}:#{id}:children", (err, childIds) =>
            return callback new SoapError 501 if err?
            return callback new SoapError 701 unless childIds.length
            async.concat(
                childIds
                (cId, callback) => @redis.hgetall "#{@uuid}:#{cId}", callback
                (err, results) ->
                    callback err, results
            )

    # Get metadata of object with @id.
    fetchObject: (id, callback) ->
        @redis.hgetall "#{@uuid}:#{id}", (err, object) ->
            return callback new SoapError 501 if err?
            return callback new SoapError 701 unless Object.keys(object).length > 0
            callback null, object

    getUpdateId: (id, callback) ->
        getId = (id, callback) =>
            @redis.get "#{@uuid}:#{id}:updateid", (err, updateId) ->
                return callback new SoapError 501 if err?
                callback null, updateId

        if id is 0
            return callback null, @services.ContentDirectory.stateVars.SystemUpdateID.value
        else
            @redis.exists "#{@uuid}:#{id}:updateid", (err, exists) =>
                # If this ID doesn't have an updateid key, get parent's updateid.
                if exists is 1
                    getId id, callback
                else
                    @redis.hget "#{@uuid}:#{id}", 'parentid', (err, parentId) =>
                        getId parentId, callback

module.exports = MediaServer
