# Implements [ContentDirectory:1] [1].
#
# [1]: http://upnp.org/specs/av/av1/
#
# vim: ts=2 sw=2 sts=2

"use strict"

async = require 'async'
fs  = require 'fs'
log   = new (require 'log')
mime  = require 'mime'
redis = require 'redis'
xml   = require 'xml'
mime.define 'audio/flac': ['flac']

Service = require './Service'
{HttpError,SoapError} = require '../errors'
utils = require '../utils'

# Capitalized properties are native UPnP control actions.
class ContentDirectory extends Service

  constructor: (@device) ->
    super
    @startDb()

  type: 'ContentDirectory'
  stateVars:
    SystemUpdateID: { value: 0, evented: yes }
    ContainerUpdateIDs: { value: '', evented: yes }
    SearchCapabilities: { value: '', evented: yes }
    SortCapabilities: { value: '*', evented: no }


  actionHandler: (action, options, cb) ->
    # Optional actions not (yet) implemented.
    optionalActions = [ 'Search', 'CreateObject', 'DestroyObject',
                        'UpdateObject', 'ImportResource', 'ExportResource',
                        'StopTransferResource', 'GetTransferProgress' ]
    return @optionalAction cb if action in optionalActions

    # State variable actions and associated XML element names.
    stateActions =
      GetSearchCapabilities: 'SearchCaps'
      GetSortCapabilities: 'SortCaps'
      GetSystemUpdateID: 'Id'
    return @getStateVar action, stateActions[action], cb if action of stateActions

    switch action
      when 'Browse'
        browseCallback = (err, resp) =>
          cb null, (if err? then @buildSoapError(err) else resp)

        switch options?.BrowseFlag
          when 'BrowseMetadata'
            @browseMetadata options, browseCallback
          when 'BrowseDirectChildren'
            @browseChildren options, browseCallback
          else
            browseCallback new SoapError 402
      else
        cb null, @buildSoapError new SoapError(401)

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

  browseChildren: (options, cb) ->
    id = parseInt(options.ObjectID or 0)
    start = parseInt(options.StartingIndex or 0)
    max = parseInt(options.RequestedCount or 0)
    sort = if utils.isString options.SortCriteria then options.SortCriteria else null

    @fetchChildren id, sort, (err, objects) =>
      return cb err if err?
      # Limit matches. Should be done before fetch instead.
      end = if max is 0 then objects.length - 1 else start + max
      matches = objects[start..end]
      @getUpdateId id, (err, updateId) =>
        cb err, @buildSoapResponse 'Browse',
          NumberReturned: matches.length
          TotalMatches: objects.length
          Result: @buildDidl matches
          UpdateID: updateId

  browseMetadata: (options, cb) ->
    id = parseInt(options?.ObjectID or 0)
    @fetchObject id, (err, object) =>
      return cb err if err?
      @getUpdateId id, (err, updateId) =>
        cb err, @buildSoapResponse 'Browse',
          NumberReturned: 1
          TotalMatches: 1
          Result: @buildDidl [ object ]
          UpdateID: updateId


  addMedia: (parentID, media, cb = ->) ->
    unless media.class? and media.title?
      return cb new Error 'Missing required property.'

    buildObject = (object, cb) =>
      object.type = /object\.(\w+)/.exec(object.class)[1]
      object.contenttype = 'audio/m3u' if object.class is 'object.container.album.musicAlbum'
      if object.type is 'item'
        object.contenttype ?= mime.lookup object.location
        @addContentType object.contenttype
        fs.stat object.location, (err, stats) ->
          object.filesize = stats?.size or 0
          cb null, object
      else
        cb null, object

    buildObject media, (err, object) => @insertContent parentID, object, cb


  # Add object to Redis data store.
  insertContent: (parentID, object, cb) ->
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
      cb err, id


  # Remove object with `id` and all its children.
  removeContent: (id, cb) ->
    remove = (id) =>
      # Remove from parent's children set.
      @redis.hget id, "parentid", (err, parentID) =>
        @redis.srem "#{parentID}:children", "#{id}"
      @redis.smembers "#{id}:children", (err, childIds) =>
        # If no children were found, it's only `id`.
        if err? or childIds.length is 0
          keys = [ id ]
        # Otherwise add related fields and recurse.
        else
          keys = childIds.concat [ id, "#{id}:children", "#{id}:updateid" ]
          remove childId for childId in childIds
        @redis.del keys
    remove id
    # Return value shouldn't matter to client, call back immediately.
    cb null


  # Get metadata of all direct children of object with @id.
  fetchChildren: (id, sortCriteria = '+upnp:track,+dc:title', cb) ->
    sortFields = []
    # `sortCriteria` is like `+dc:title,-upnp:artist` where - is descending.
    return cb new SoapError 709 unless /^(\+|-)\w+:\w+/.test sortCriteria
    for sort in sortCriteria.split(',')
      [ dir, sortField ] = /^(\+|-)\w+:(\w+)$/.exec(sort)[1...]
      s = name: sortField
      # Functions to prepare value for comparison.
      s['primer'] =
        if sortField in [ 'track', 'length' ]
          parseInt
        else if sortField in [ 'title', 'artist' ]
          (s) -> s.toLowerCase()
      s['reverse'] = true if dir is '-'
      sortFields.push s

    @redis.smembers "#{id}:children", (err, childIds) =>
      return cb new SoapError 501 if err?
      return cb new SoapError 701 unless childIds.length
      async.concat childIds,
        (cId, cb) => @redis.hgetall cId, cb
        (err, results) ->
          results = results.sort utils.sortObject sortFields...
          cb err, results

  # Get metadata of object with @id.
  fetchObject: (id, cb) ->
    @redis.hgetall id, (err, object) ->
      return cb new SoapError 501 if err?
      return cb new SoapError 701 unless Object.keys(object).length > 0
      cb null, object

  getUpdateId: (id, cb) ->
    getId = (id, cb) =>
      @redis.get "#{id}:updateid", (err, updateId) ->
        return cb new SoapError 501 if err?
        cb null, updateId

    if id is 0
      return cb null, @stateVars.SystemUpdateID.value
    else
      @redis.exists "#{id}:updateid", (err, exists) =>
        # If this ID doesn't have an updateid key, get parent's updateid.
        if exists is 1
          getId id, cb
        else
          @redis.hget id, 'parentid', (err, parentId) =>
            getId parentId, cb


  # Handle HTTP request if it's a resource request, otherwise pass  to super.
  requestHandler: (args, cb) ->
    { action, id } = args
    return super(arguments...) unless action is 'resource'
    @fetchObject id, (err, object) =>
      return cb new HttpError 500 if err?
      cb2 = (err, data) ->
        return cb new HttpError 500 if err?
        cb null, data,
          'Content-Type': object.contenttype
          'Content-Length': object.filesize or Buffer.byteLength data
      if object.type is 'item'
        fs.readFile object.location, cb2
      else if object.class is 'object.container.album.musicAlbum'
        @buildM3u id, cb2
      else
        return cb new HttpError 404


  # Build a DIDL XML structure for items/containers in the MediaServer device.
  buildDidl: (data) ->
    # Build an array of elements contained in an object element.
    buildObject = (obj) =>
      el = []
      el.push {
        _attr:
          id: obj.id
          parentID: obj.parentid
          restricted: 'true'
      }
      el.push 'dc:title': obj.title
      el.push 'upnp:class': obj.class
      if obj.creator?
        el.push 'dc:creator': obj.creator
        el.push 'upnp:artist': obj.creator
      if obj.location? and obj.contenttype?
        attrs = protocolInfo: "http-get:*:#{obj.contenttype}:*"
        attrs['size'] = obj.filesize if obj.filesize?
        el.push 'res': [
          _attr: attrs
          @makeUrl "/service/#{@type}/resource/#{obj.id}" ]
      el

    ((body={})['DIDL-Lite']=[]).push
      _attr:
        'xmlns': @makeNS 'metadata', '/DIDL-Lite/'
        'xmlns:dc': 'http://purl.org/dc/elements/1.1/'
        'xmlns:upnp': @makeNS 'metadata', '/upnp/'
    for object in data
      type = /object\.(\w+)/.exec(object.class)[1]
      o = {}
      o[type] = buildObject object
      body['DIDL-Lite'].push o

    xml [ body ]


  buildM3u: (id, cb) ->
    @redis.smembers "#{id}:children", (err, childIDs) =>
      m3u = for childID in childIDs
        @makeUrl "/service/#{@type}/resource/#{childID}"
      cb null, m3u.join '\n'



module.exports = ContentDirectory
