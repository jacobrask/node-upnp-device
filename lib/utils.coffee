# Utility functions.
#
# [1]: http://upnp.org/specs/av/av1/
#
# vim: ts=2 sw=2 sts=2

"use strict"

# Get object's `[[Class]]` property.
objectType = (obj) -> /\[object (\w+)\]/.exec(Object::toString.call(obj))[1]
isFunction = exports.isObject = (obj) -> objectType(obj) is 'Function'
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

# Sort an object on any number of keys.
# An argument is a string or an object with `name`, `primer`, `reverse`.
sortObject = exports.sortObject = ->
  fields = [].slice.call arguments
  (A, B) ->
    for field in fields
      key = if isObject field then field.name else field
      primer = if isFunction field.primer then field.primer else (v) -> v
      reverse = if field.reverse then -1 else 1
      a = primer A[key]
      b = primer B[key]
      result =
        if a < b
          reverse * -1
        else if a > b
          reverse * 1
        else
          reverse * 0
      break if result isnt 0
    result
