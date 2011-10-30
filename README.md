UPnP Devices in Node.js
=======================

upnp-device lets you create [UPnP Devices](http://upnp.org/sdcps-and-certification/standards/sdcps/) in Node.js.

upnp-device is currently in a very early development phase and the first target is to implement the MediaServer:1 specification.

Features so far
---------------
* Generate a device description
* Send SSDP notifications

Usage
-----
```javascript
var upnp = require('upnp-device');

options = {
    device: {
        type: 'MediaServer',
        version: 1
    },
    app: {
        name: 'Bragi',
        version: '0.0.1'
    }
}
// Generate a UPnP device description
upnp.createDevice(options, function(err, msg) {
    console.log(msg); 
});

// Send out SSDP announcements about the Device/Application availability
// Keeps sending out notifications in a random interval
upnp.announce(function(err, msg) {
    console.log(msg); 
});
```
