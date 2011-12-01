"use strict"

{parseUuidFile} = require '../lib/helpers'

exports["Get UUID from JSON data."] = (test) ->
    ((obj={})[type = "buzz"]={})[name = "fizz"] = uuid = "uuid:7baea6c0-1c15-11e1-bddb-0800200c9a66"
    parseUuidFile JSON.stringify(obj), type, name, (err, parsedUuid) ->
        test.ifError err
        test.equal uuid, parsedUuid
        test.done()

exports["Return error when UUID isn't found."] = (test) ->
    parseUuidFile '{ "foo": "bar" }', 'Not Name', 'Not Type', (err, parsedUuid) ->
        test.ok err?, "Expected to return error."
        test.done()
