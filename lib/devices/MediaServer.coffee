# UPnP Media Server. See [specification] [1].
#
# [1]: http://upnp.org/specs/av/av1/
#
# vim: ts=2 sw=2 sts=2

"use strict"

Device = require './Device'

services =
  ConnectionManager: require '../services/ConnectionManager'
  ContentDirectory:  require '../services/ContentDirectory'

class MediaServer extends Device

  constructor: ->
    super
    for type, service of services
      @services[type] = new service @
      @emit 'newService', type
    @init()

  type: 'MediaServer'
  version: 1

  addMedia: (parentID, media, cb) ->
    unless media.class? and media.title?
      return cb new Error 'Missing required object property.'
    @services.ContentDirectory.addMedia arguments...
  removeMedia: -> @services.ContentDirectory.removeContent arguments...


module.exports = MediaServer
