UPnP Devices in Node.js
=======================

upnp-device lets you create [UPnP Devices](http://upnp.org/sdcps-and-certification/standards/sdcps/) in Node.js.

upnp-device is currently in a ___very early development phase___. The first target is to implement the MediaServer:1 specification.

Features so far
---------------

* Generate MediaServer device and service descriptions
* Send SSDP notifications about created device

Install
-------

upnp-device is not ready for npm yet, so you need to install manually. CoffeeScript is required for building.

```bash
$ git clone https://github.com/jacobrask/node-upnp-device.git ./node_modules/upnp-device
$ cd node_modules/upnp-device
$ npm install -d
# npm install -g coffee-script
$ cake build
```

Usage
-----

Node 0.4.12 recommended. upnp-device is ___not___ compatible with Node 0.6.0 due to some missing UDP features in 0.6.0.

```javascript
var upnp = require('upnp-device');

// Generate an UPnP device description and announce it via SSDP
upnp.createDevice('My Media App', 'MediaServer', function(err, server) {
    if (err != null) {
        throw err;
    }
    console.log('Device successfully started');
});
```

See also
--------

 * [UPnP client](https://github.com/TooTallNate/node-upnp-client) by TooTallNate

Development
-----------

upnp-device is written in [CoffeeScript](http://coffeescript.org).

Contributions and comments are welcome on GitHub or IRC (jacobrask@FreeNode).
