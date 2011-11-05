UPnP Devices in Node.js
=======================

upnp-device lets you create [UPnP Devices](http://upnp.org/sdcps-and-certification/standards/sdcps/) in Node.js.

upnp-device is currently in a very early development phase and the first target is to implement the MediaServer:1 specification.

Features so far
---------------
* Generate a device description
* Send SSDP notifications

Implemented specifications
--------------------------
* Started: UPnP Device Architecture version 1.0

Usage
-----

All errors are passed back to the applications as the first argument of the callback, letting you handle errors in whatever way you prefer.

```javascript
var upnp = require('upnp-device');

// Generate a UPnP device description and announce it via SSDP
upnp.createDevice('My Media App', 'MediaServer', function(err, server) {
    if (err !== null) {
        throw err;
    }
    console.log('Device successfully started');
});
```
