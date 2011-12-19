# Implements UPnP Device Architecture version 1.0
# http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/

"use strict"

fs   = require 'fs'
http = require 'http'
log  = new (require 'log')
url  = require 'url'
uuid = require 'node-uuid'
xml  = require 'xml'
{Parser:XmlParser} = require 'xml2js'

DeviceControlProtocol = require '../DeviceControlProtocol'
{HttpError,SoapError} = require '../errors'
utils = require '../utils'

class Service extends DeviceControlProtocol

    constructor: (@device) ->

    # Control action. Most actions build a SOAP response and calls back.
    action: (action, data, cb) ->
        (new XmlParser).parseString data, (err, data) =>
            @actionHandler action, data['s:Body']["u:#{action}"], cb


    # Event subscriptions.
    subscribe: (urls, reqTimeout) ->
        sid = "uuid:#{uuid()}"
        (@subs?={})[sid] = new Subscription sid, urls, @
        timeout = @subs[sid].selfDestruct reqTimeout
        log.debug "Added new subscription for #{@type} with #{sid}, expiring in #{timeout}s."
        { sid, timeout: "Second-#{timeout}" }

    renew: (sid, reqTimeout) ->
        unless @subs[sid]?
            log.warning "Got subscription renewal request but could not find device #{sid}."
            return null
        timeout = @subs[sid].selfDestruct reqTimeout
        log.debug "Renewing subscription #{sid}, expiring in #{timeout}s."
        { sid, timeout: "Second-#{timeout}" }

    unsubscribe: (sid) ->
        log.debug "Deleting subscription #{sid}."
        delete @subs[sid] if @subs[sid]?


    # For optional actions not (yet) implemented.
    optionalAction: (cb) -> cb null, @buildSoapError new SoapError 602


    # Service actions that only return a State Variable.
    getStateVar: (action, elName, cb) ->
        # Actions start with 'Get' followed by variable name.
        varName = /^(Get)?(\w+)$/.exec(action)[2]
        return @buildSoapError new SoapError(404) unless varName of @stateVars
        (el={})[elName] = @stateVars[varName].value
        cb null, @buildSoapResponse action, el


    # Notify all subscribers of updated state variables.
    notify: -> @subs[uuid].notify() for uuid of @subs


    # Build a SOAP response XML document.
    buildSoapResponse: (action, args) ->
        # Create an action element.
        (body={})["u:#{action}Response"] = utils.objectToArray args,
            [ _attr: { 'xmlns:u': @makeType() } ]

        '<?xml version="1.0"?>' + xml [ 's:Envelope': [
            { _attr: {
                'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/'
                's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/' } }
            { 's:Body': [ body ] }
        ] ]


    # Build a SOAP error XML document.
    buildSoapError: (error) ->
        '<?xml version="1.0"?>' + xml [ 's:Envelope': utils.objectToArray(
            _attr:
                'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/'
                's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/'
            's:Body': [
                's:Fault': utils.objectToArray(
                    faultcode: 's:Client'
                    faultstring: 'UPnPError'
                    detail: [ 'UPnPError': utils.objectToArray(
                        _attr: 'xmlns:e': @makeNS 'control'
                        errorCode: error.code
                        errorDescription: error.message ) ]
                ) ]
        ) ]


    # Build an event notification XML document.
    buildEvent: (vars) ->
        '<?xml version="1.0"?>' + xml [ 'e:propertyset': [
            { _attr: 'xmlns:e': @makeNS 'event' }
            { 'e:property': utils.objectToArray vars }
        ] ]


    # Send HTTP request with event info to `urls`.
    postEvent: (urls, sid, eventKey, data) ->
        for eventUrl in urls
            u = url.parse eventUrl
            headers =
                nt: 'upnp:event'
                nts: 'upnp:propchange'
                sid: sid
                seq: eventKey.toString()
                'content-length': Buffer.byteLength data
                'content-type': null
            options =
                host: u.hostname
                port: u.port
                method: 'NOTIFY'
                path: u.pathname
                headers: @device.makeHeaders headers
            req = http.request options
            req.on 'error', (err) -> throw err
            req.write data
            req.end()


    # Build `service` element.
    buildServiceElement: ->
        [ { serviceType: @makeType() }
          { eventSubURL: "/service/#{@type}/event" }
          { controlURL: "/service/#{@type}/control" }
          { SCPDURL: "/service/#{@type}/description" }
          { serviceId: "urn:upnp-org:serviceId:#{@type}" } ]


    # Handle service related HTTP requests.
    requestHandler: (args, cb) ->
        { action, req } = args
        { method } = req
        switch action
            when 'description'
                # Service descriptions are static files.
                fs.readFile("#{__dirname}/#{@type}.xml", 'utf8', (err, file) ->
                    cb (if err? then new HttpError 500 else null), file)

            when 'control'
                serviceAction = /:\d#(\w+)"$/.exec(req.headers.soapaction)?[1]
                log.debug "#{serviceAction} on #{@type} invoked by #{req.client.remoteAddress}."
                # Service control messages are `POST` requests.
                return cb new HttpError 405 if method isnt 'POST' or not serviceAction?
                data = ''
                req.on 'data', (chunk) -> data += chunk
                req.on 'end', =>
                    @action serviceAction, data, (err, soapResponse) ->
                        cb err, soapResponse, ext: null

            when 'event'
                {sid, timeout, callback: urls} = req.headers
                log.debug "#{method} on #{@type} received from #{req.client.remoteAddress}."
                if method is 'SUBSCRIBE'
                    if urls?
                        # New subscription.
                        err = new HttpError(412) unless /<http/.test urls
                        resp = @subscribe urls.slice(1, -1), timeout
                    else if sid?
                        # `sid` is subscription ID, so this is a renewal request.
                        resp = @renew sid, timeout
                    else
                        err = new HttpError 400
                    err ?= new HttpError(412) unless resp?
                    cb err, null, resp

                else if method is 'UNSUBSCRIBE'
                    @unsubscribe sid if sid?
                    # Unsubscription response is simply `200 OK`.
                    cb (if sid? then null else new HttpError 412)

                else
                    cb new HttpError 405

            else
                callback new HttpError 404



class Subscription
    constructor: (@uuid, urls, @service) ->
        @eventKey = 0
        @minTimeout = 1800
        @urls = urls.split ','
        @notify()

    selfDestruct: (timeout) ->
        clearTimeout(@destructionTimer) if @destructionTimer?
        # `timeout` is like `Second-(seconds|infinite)`.
        time = /Second-(infinite|\d+)/.exec(timeout)[1]
        if time is 'infinite' or parseInt(time) > @minTimeout
            time = @minTimeout
        else
            time = parseInt(time)
        @destructionTimer = setTimeout(
            => @service.unsubscribe @uuid
            time * 1000)
        # Return actual time until unsubscription.
        time

    notify: ->
        # Specification states that all variables are sent out to all clients
        # even if only one variable changed.
        log.debug "Sending out event for current state variables to #{@urls}"
        eventedVars = {}
        for key, val of @service.stateVars when val.evented
            eventedVars[key] = val.value
        eventXML = @service.buildEvent eventedVars
        @service.postEvent @urls, @uuid, @eventKey, eventXML
        @eventKey++


module.exports = Service
