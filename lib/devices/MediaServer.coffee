# Implements MediaServer:1
# http://upnp.org/specs/av/av1/

mime = require 'mime'
redis = require 'redis'

Device = require('./Device')

class MediaServer extends Device

    constructor: (name, schema) ->
        @type = 'MediaServer'
        @version = 1

        @services = { }
        @services.ContentDirectory = new (require '../services/ContentDirectory')(@)
        @services.ConnectionManager = new (require '../services/ConnectionManager')(@)
        @redis = redis.createClient()
        @redis.on 'error', (err) ->
            throw err if err?
        # Flush database. FIXME.
        @redis.flushdb()
        super name, schema


    addMedia: (parentID, media, callback) ->

        buildContainer = (obj) =>
            cnt =
                class: 'object.container.'
                restricted: '0'
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
                restricted: '0'
                title: obj.title or 'Untitled'
                creator: obj.creator or parent.creator
                res: obj.location

            mimeType = mime.lookup(obj.location)
            @services.ContentDirectory.addContentType mimeType

            # Try to figure out type from parent type.
            obj.type ?=
                switch parent.type
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

        cnt = buildContainer media
        @insertContainer parentID, cnt, (err, cntId) =>
            for child in media.children
                item = buildItem child, media
                @insertItem cntId, item, (err, itemId) ->
                    console.log itemId

    insertContainer: (parentID, cnt, callback) ->
        # Increment and return Object ID.
        @redis.incr "#{@uuid}:next", (err, id) =>
            # Add Object ID to parent object's child set.
            @redis.sadd "#{@uuid}:container:#{parentID}:children", id
            # Increment each time container is modified.
            @redis.incr "#{@uuid}:container:#{id}:updateid"
            # Add ID's to container data structure and insert into database.
            cnt.id = id
            cnt.parentid = parentID
            @redis.hmset "#{@uuid}:container:#{id}", cnt
            callback err, id

    insertItem: (parentID, item, callback) ->
        # Increment and return Object ID.
        @redis.incr "#{@uuid}:next", (err, id) =>
            # Add Object ID to parent object's child set.
            @redis.sadd "#{@uuid}:container:#{parentID}:children", id
            # Increment each time parent container is modified.
            @redis.incr "#{@uuid}:container:#{parentID}:updateid"
            # Add ID's to item data structure and insert into database.
            item.id = id
            item.parentid = parentID
            @redis.hmset "#{@uuid}:item:#{id}", item
            callback err, id

module.exports = MediaServer
