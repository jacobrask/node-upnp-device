# Implements MediaServer:1
# http://upnp.org/specs/av/av1/

async = require 'async'
mime = require 'mime'
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

        buildObject = (obj, parent) ->
            # If an object has children, it's a container.
            if obj.children?
                buildContainer(obj)
            else
                buildItem(obj, parent)

        buildContainer = (obj) ->
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
            cnt

        buildItem = (obj, parent) =>
            item =
                class: 'object.item'
                title: obj.title or 'Untitled'
                creator: obj.creator or parent.creator
                res: obj.location

            mimeType = mime.lookup(obj.location)
            @services.ContentDirectory.addContentType mimeType

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
            item
        
        # Insert root element and then iterate through its children and insert them.
        @insertContent parentID, buildObject(media), (err, id) =>
            buildChildren id, media

        buildChildren = (parentID, parent) =>
            parent.children ?= []
            for child in parent.children
                @insertContent parentID, buildObject(child, parent), (err, childID) ->
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

    # Get all direct children of ID.
    fetchChildren: (id, callback) ->
        @redis.smembers "#{@uuid}:#{id}:children", (err, childIds) =>
            if err
                return callback new SoapError 501
            unless childIds.length
                return callback new SoapError 701
            async.concat(
                childIds
                (cId, callback) => @redis.hgetall "#{@uuid}:#{cId}", callback
                callback
            )

    fetchObject: (id, callback) ->
        @redis.hgetall "#{@uuid}:#{id}", callback

module.exports = MediaServer
