# UPnP Devices in Node.js

upnp-device lets you create [UPnP Devices][upnp-dcp] in Node.js. The goal is to have an easy to use API, rather than exposing all UPnP internals.

upnp-device is currently in a ___very early development phase___. The first target is to implement the MediaServer:1 specification.


# Features so far

* MediaServer:1
 * Device and service descriptions over HTTP.
 * ConnectionManager service.
* SSDP notifications and replies.


# Install

upnp-device is not ready for npm yet, so you need to install manually by cloning this repository.

Additionally, to use the MediaServer device you need to install [redis][http://redis.io]. 


# Documentation

## Basic usage

Node 0.4.12 recommended. upnp-device is ___not___ compatible with Node 0.6.0 due to some missing UDP features in 0.6.0.

```javascript
var upnp = require('upnp-device');

upnp.createDevice('MediaServer', 'My Media Application', startDevice);

var startDevice = function(err, device) {
    device.start();
    device.addMedia(parentId, media, function(err, id) {
        console.log("Added new media with ID:" + id);
    });
};
```

## API

### upnp.createDevice(type, name, callback)

* type - A device specified by the [UPnP forum][upnp-dcp]. Only __MediaServer__ is currently supported.
* name - The name of the device as it shows up in the network.
* callback(err, device) - Called when device creation's asynchronous operations are completed. Returns a device object.

### device.start([callback])

* `callback(err)` - Called when device servers (SSDP, HTTP) are started and the device has been announced to the network.

### device.addMedia(parentID, media[, callback])

Applies to MediaServer.

UPnP Device only stores this info for as long as it is running. It is the responsibility of the client to store media information across restarts.

The metadata needs to be extracted by the client, either through user input or by reading for example ID3 tags.

* parentID - Parent container of media. 0 means root.
* media - A JSON structure of containers and items. See examples below.
* [callback(err, id)] - Called when all media has been added to the database. Returns the ID of the top container added.

```javascript
{
    type: 'folder|musicalbum|photoalbum|musicartist|musicgenre|moviegenre',
    title: 'Container title',
    creator: 'Artist, photographer...',
    description: 'Container description',
    genre: 'Music or movie genre',
    children: [ {
        type: 'musictrack|audio|image|photo|movie|musicvideo|video|audiobook, inferred from parent type if applicable.',
        title: 'Item title',
        creator: 'Inherits from parent.',
        description: 'Item description',
        language: 'Inherits from parent.',
        date: 'Inherits from parent.',
        genre: 'Music or movie genre. Inherits from parent.',
        res: 'Path or URI to media resource.',
        mimeType: 'Internet media type. Guessed from filename if possible.'
    } ]
}
```

This might look slightly complex, but all most properties are optional and many inherit from parents. Some more examples:

```javascript
{
    type: 'musicalbum',
    title: 'To the Extreme',
    creator: 'Vanilla Ice',
    genre: 'Rap',
    date: '1990',
    children: [ {
        title: 'Ice Ice Baby',
        res: '/media/music/ice_ice_baby.mp3'
    }, {
        title: 'Yo Vanilla',
        res: '/media/music/yo_vanilla.mp3'
    } ]
}
```

### device.removeMedia(id[, callback])

Applies to MediaServer.

* id - ID of container to remove. All its children will be removed. Currently individual items cannot be removed.
* [callback(err)]

### device.getChildren(id, callback)

Applies to MediaServer.

* id - Container ID.
* callback(err, children) - Returns an array of objects with the container's immediate children. Can be containers or items.

```javascript
{
    id: '1290',
    title: 'Ice Ice Baby',
    creator: 'Vanilla Ice',
    date: '1990',
    res: '/media/music/vanilla_ice-ice_ice_baby.mp3'
}
```

# See also

 * [UPnP client](https://github.com/TooTallNate/node-upnp-client) by TooTallNate
 * [UPnP.org][upnp]

# Development

upnp-device is written in [CoffeeScript](http://coffeescript.org).

`console.log` and `console.info` are muted by default, unmute with `NODE_DEBUG=upnp-device`:

```bash
$ NODE_DEBUG=upnp-device node myapp.js
# or
$ export NODE_DEBUG=upnp-device
$ node myapp.js
```

Contributions and comments are welcome on GitHub or IRC (jacobrask@FreeNode).

[upnp]: http://upnp.org
[upnp-dcp]: http://upnp.org/sdcps-and-certification/standards/sdcps/
