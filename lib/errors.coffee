# Some functions depend on `@` being bound to a Device or Service.
# Use this error if the context doesn't seem right.
class exports.ContextError extends Error
    constructor: (message) ->
        @name = 'ContextError'
        @message = message or "Invoked function in bad `this` context."
        Error.captureStackTrace @, ContextError

http = require 'http'
# Use http module's `STATUS_CODES` static to get error messages.
class exports.HttpError extends Error
    constructor: (@code) ->
        @message = http.STATUS_CODES[@code]
