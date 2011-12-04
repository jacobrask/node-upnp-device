# Some functions depend on `@` being bound to a Device or Service.
# Use this error if the context doesn't seem right.
class exports.ContextError extends Error
    constructor: (message) ->
        @name = 'ContextError'
        @message = message or "Invoked function in bad `this` context."
        Error.captureStackTrace @, ContextError

# Use http module's `STATUS_CODES` static to get error messages.
http = require 'http'
class exports.HttpError extends Error
    constructor: (@code) ->
        @message = http.STATUS_CODES[@code]

# Error object with predefined UPnP SOAP error code-message combinations.
class exports.SoapError extends Error
    constructor: (@code) ->
        STATUS_CODES =
            401: "Invalid Action"
            402: "Invalid Args"
            501: "Action Failed"
            600: "Argument Value Invalid"
            601: "Argument Value Out of Range"
            602: "Optional Action Not Implemented"
            604: "Human Intervention Required"
            701: "No Such Object"
            709: "Invalid Sort Criteria"
        @message = STATUS_CODES[@code]
