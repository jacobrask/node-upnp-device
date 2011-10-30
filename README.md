UPnP Devices in Node.js
=======================

upnp-device lets you create [UPnP Devices](http://upnp.org/sdcps-and-certification/standards/sdcps/) in Node.js.

upnp-device is currently in a very early development phase.

Features so far
---------------
* Generate a device description
* Send SSDP notifications

Usage
-----
```javascript
var upnp = require('upnp-device');

// Generate a UPnP device description
upnp.createDevice('MediaServer', '1.0', function(err, msg) { 
    console.log(msg); 
});

// Send out SSDP announcements about the Device/Application availability
// Keeps sending out notifications in a random interval
upnp.announce('My Application', '1.0', function(err, msg) { 
    console.log(msg); 
});
```
