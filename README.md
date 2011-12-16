# UPnP Devices in Node.js

upnp-device lets you create [UPnP Devices][upnp-dcp] in Node.js. The goal is to have an easy to use API, rather than exposing all UPnP internals.


# Limitations

* Only implemented device specification is MediaServer:1
* MediaServer can only serve media from local file system
* And more...


# Install

upnp-device is not ready for npm yet, so you need to install manually by cloning this repository.

Node 0.4.12 is recommended. upnp-device is ___not___ compatible with Node 0.6.x due to some missing UDP features in 0.6.x. They are expected to be implemented fairly soon, and then upnp-device will be ported to 0.6.x.

Additionally, to use the MediaServer device you need to install [redis](http://redis.io).


# Documentation

## Basic usage

### JavaScript

```javascript
var upnp = require('upnp-device');

var mediaServer = upnp.createDevice('MediaServer', 'My Media Application');

mediaServer.on('ready', function() {
    mediaServer.addMedia(0, media, function(err, id) {
        console.log("Added new media with ID:" + id);
    });
    mediaServer.announce();
});
```

## API

### upnp.Device

#### Event: 'ready'

#### Event: 'error'

### upnp.createDevice(type, name[, address])

* type - A device specified by the [UPnP Forum][upnp-dcp].
* name - The name of the device as it shows up in the network.
* address - Optional IP address to bind server to.

### device.announce()

Announces the device over SSDP to the local network.

### device.addMedia(parentID, media[, callback])

Applies to MediaServer.

The metadata needs to be extracted by the client, either through user input or by reading for example ID3 tags.

* parentID - Parent container of media. 0 means root.
* properties - Object with class properties. Example below.
* [callback(err, id)] - Called when all media has been added to the database. Returns the ID of the top container added.

```
container = {
    class: 'object.container.album.musicAlbum',
    title: 'My album' };
item = {
    class: 'object.container.audioItem.musicTrack',
    title: 'My song',
    creator: 'An artist',
    location: '/media/mp3/an_artist-my_song.mp3',
    album: 'My album' };
```

Other official UPnP classes and properties are defined in the [MediaServer specification][upnp-av].

The server only stores this info for as long as it is running. It is the responsibility of the client to store media information across restarts if desired.


# Development

upnp-device is written in [CoffeeScript](http://coffeescript.org).

Contributions and comments are welcome on GitHub or IRC (jacobrask@FreeNode).

## Acronyms

* **UDA**: [UPnP Device Architecture] [upnp-uda]
* **DCP**: [UPnP Device Control Protocol] [upnp-dcp]
* **DIDL**: Digital Item Declaration Language, XML dialect for describing media. To describe content in AV devices, UPnP uses DIDL-Lite, a subset of DIDL.
* **UPnP AV**: [UPnP Audio/Video] [upnp-av]


# See also

 * [UPnP.org][upnp]
 * [UPnP client](https://github.com/TooTallNate/node-upnp-client) by @TooTallNate
 * [Gammatron](https://github.com/mattijs/Gammatron) by @mattijs

[upnp]: http://upnp.org
[upnp-dcp]: http://upnp.org/sdcps-and-certification/standards/sdcps/
[upnp-uda]: http://upnp.org/sdcps-and-certification/standards/device-architecture-documents/
[upnp-av]: http://upnp.org/specs/av/av1/
