"use strict"

# Get object's `[[Class]]` property.
objectType = (obj) -> /\[object (\w+)\]/.exec(Object::toString.call(obj))[1]
isObject = exports.isObject = (obj) -> objectType(obj) is 'Object'
isString = exports.isString = (obj) -> objectType(obj) is 'String'

# Make each key/value pair in object into separate objects in `arr`.
objectToArray = exports.objectToArray = (obj, arr = []) ->
    throw new TypeError("Not an object.") unless isObject obj
    Object.keys(obj).map (key) ->
        o = {}
        o[key] = obj[key]
        arr.push o
    arr

# Parse JSON string to object, returning an empty object on invalid JSON.
parseJSON = exports.parseJSON = (str) ->
    throw new TypeError("Not a string.") unless isString str
    try
        JSON.parse str
    catch e
        { }
