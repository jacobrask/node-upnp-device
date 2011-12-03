"use strict"

# Return a copy of `orig` extended with `ext`.
unless typeof Object.extend is 'function'
    Object.defineProperty Object, 'extend',
        value: (orig, ext) ->
            props = {}
            for name in Object.getOwnPropertyNames(ext) when name not in orig
                props[name] = Object.getOwnPropertyDescriptor ext, name
            Object.create orig, props
        configurable: yes
        writable: yes

# Make each key/value pair separate objects in `arr`.
unless typeof Object.toArray is 'function'
    Object.defineProperty Object, 'toArray',
        value: (obj, arr = []) ->
            Object.keys(obj).map (key) ->
                o = {}
                o[key] = obj[key]
                arr.push o
            arr
        configurable: yes
        writable: yes

# Parse JSON string to object, returning an empty object on invalid JSON.
unless typeof String::toObject is 'function'
    Object.defineProperty String::, 'toObject',
        value: ->
            try
                JSON.parse @
            catch e
                { }
        configurable: yes
        writable: yes
