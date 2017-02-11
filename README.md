
= Installation

Requirements: taglib, mysql, rails, ruby 2.3.1

Debian/Ubuntu: sudo apt-get install libtag1-dev
Fedora/RHEL: sudo yum install taglib-devel
Brew: brew install taglib
MacPorts: sudo port install taglib


1. Hook up chromecast audios as usual
1.1. Test with spotify or another app to make sure casts and groups play music

2. Give computer a static IP

3. Install pychromecast requirements
cd pychromecast
sudo easy_install pip
pip install --upgrade pip
sudo pip install -r requirements.txt
Install taglib, mysql, rvm, rails


DEBUG=true 

= Troubleshooting

1. No sound

* Make sure it works w/ spotify or another app
* Check the rails log. If the player says its status is 'IDLE', rather than 'PLAYING' or 'BUFFERING' then the cast isn't able to hit the web server.


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



