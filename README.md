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
```javascript
var upnp = require('upnp-device');

options = {
    device: 'MediaServer',
    services: [ 'ConnectionManager', 'ContentDirectory' ],
    app: {
        name: 'Bragi',
        version: '0.0.1'
    }
}
// Generate a UPnP device description
upnp.createDevice(options, function(err, msg) {
    console.log(msg); 
});
```
