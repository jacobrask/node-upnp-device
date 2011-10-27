extend = (object, extenders...) ->
    return {} if not object?
    for other in extenders
        for own key, val of other
            if not object[key]? or typeof val isnt 'object'
                object[key] = val
            else
                object[key] = extend object[key], val
    object

exports.extend = extend
