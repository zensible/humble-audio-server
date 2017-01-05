
= Installation

Requirements: taglib, mysql, rails, ruby 2.3.1

Debian/Ubuntu: sudo apt-get install libtag1-dev
Fedora/RHEL: sudo yum install taglib-devel
Brew: brew install taglib
MacPorts: sudo port install taglib



= Alternate Audio Directory

You might not want many gigs of MP3s sitting on your rails server's /public directory. I personally keep it on a big ol' external USB hard drive since HD speed barely matters for such small files.

How To:

First move the public/audio directory to another drive/machine/whatever that's accessible to the rails server.

Let's say we moved it to:

/Volumes/GiantExternalHD/multiroom/audio

1. Run these commands

cd <multiroom dir>/public
ln -sf /Volumes/GiantExternalHD/multiroom/audio audio

To make sure it worked, run:

ls audio/./

You should see something like this:

music   presets.json  radio.json  spoken    white-noise

2. In your browser, refresh all your media

You should now see all of your audio appear in the app.

