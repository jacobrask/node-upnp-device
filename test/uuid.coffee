"use strict"

qc = require 'quickcheck'
assert = require 'assert'
makeUuid = require 'node-uuid'

parseUuid = (type, name, uuid) ->
    {handleUuidData} = require '../lib/helpers'
    ((obj={})[type]={})[name] = uuid
    handleUuidData JSON.stringify(obj), type, name, (err, parsedUuid) ->
        uuid is parsedUuid

qc.forAll parseUuid, qc.arbString, qc.arbString, makeUuid
