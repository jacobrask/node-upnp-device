"use strict"

assert = require 'assert'

{parseUuidFile} = require '../lib/helpers'

type = "baz"
name = "fizz"
uuid = "uuid:7baea6c0-1c15-11e1-bddb-0800200c9a66"

((obj={})[type]={})[name] = uuid

parseUuidFile JSON.stringify(obj), type, name, (err, parsedUuid) ->
    assert.ifError err
    assert.equal uuid, parsedUuid

parseUuidFile JSON.stringify(obj), "Not Name", "Not Type", (err, parsedUuid) ->
    assert.ok err?, "Expected to return error."
