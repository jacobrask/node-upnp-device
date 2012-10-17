var upnp = require('../index.js');
var myDevice = require('./MyDevice');
var device = upnp.createMyOwnDevice(myDevice, 'My Device');

device.on('ready', function() {
    device.ssdpAnnounce();
});

