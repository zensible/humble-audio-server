
# Humble Audio Server

### A Simple, Free Multiroom Audio Server

This project is a web server for streaming MP3s to your desktop web browser, mobile browser or Chromecast Audio devices.

While it competes with very featureful streaming apps such as Ampache or Plex, it has several advantages and unique features:

* Native Chromecast Audio support: servers like Ampache require you to manually use Chrome's "cast" feature.
* "Presets": once you have your Chromecasts streaming how you like, you can save that state and return to it later with a click.
* Schedule preset to run at certain days/times: For example you could wake to NPR at 8AM and go to sleep to a white white noise track at 11PM.
* Extra features for spoken word / audio books: whenever you stop playing an audio book, it will save a "bookmark" so you can resume it later from anywhere.
* Support for ancient MP3s of questionable quality, even without ID3 tags.
* Easy install

Most of all, Humble's advantage is in its simplicity. Other streaming servers try to do everything for everyone (video, album art, online channels such as TED talks, lyrics, visualizations, multiple user accounts) which tend to make them cluttered and buggy.

Humble has just one screen which works equally well on a mobile device or a browser and has a laserlike focus on the one basic feature that everyone wants: streaming MP3s to browsers and Chromecast Audios. There are no native mobile apps for it yet, but so far I've had no trouble at all just using a mobile browser.

Here are the other basic features:

* Streaming over the internet (requires a free Dynamic DNS service such as duckdns.org or your own domain)
* Basic security: you can optionally require a login/password
* Chromecast Audio Multiroom support
* Customizable color schemes
* Hackability - coders can easily modify the UI, add or remove features, etc

## Installation

There are two installation methods: simple and hacker.

Before you begin, here are the basic steps common to both:

#### 1. Set up your Chromecast Audios (optional)

If you want to stream to CCAs, install them as usual and make sure they work with an app such as Pandora.

See:

https://support.google.com/chromecast/answer/6279371?hl=en&ref_topic=6279364

#### 2. 

### Simple Installation

This method involves using a Virtual Machine with humble pre-installed, which makes it easy to set up and compatible with all platforms: Windows, Linux, Mac.

The downside is you may have to keep increasing the size of the virtual disk as your MP3 library grows. Performance might also be a bit degraded, but since we're talking MP3s here realistically even the most humble hardware should work.

#### 1. Install Virtualbox:

https://www.virtualbox.org/wiki/Downloads

#### 2. Download the Humble Media Server Virtual Machine:

#### 3. Double-click the VM and go through the setup

#### 4. Copy your MP3s to the shared folder you set up

### Hacker Installation

Use this method if you want to install a native server on a Mac or Ubuntu machine, or on alternative hardware such as the Raspberry Pi or Intel Edison. I haven't tried it on Windows, but I doubt it would work due to all the *NIX-specific libraries this project requires.

1. Give the computer a static IP

2. Install pychromecast requirements

## Python Requirements

This app requires python 2.7 or newer and the 'pip' installer.

Mac:

Macs should all ship with Python 2.7, so you just need pip:

sudo easy_install pip
pip install --upgrade pip

Ubuntu:

sudo add-apt-repository ppa:fkrull/deadsnakes
sudo apt-get update
sudo apt-get install python2.7
sudo apt install python-pip
sudo apt-get install python-dev

See: http://askubuntu.com/questions/101591/how-do-i-install-python-2-7-2-on-ubuntu

## PyChromecast requirements:

cd pychromecast
sudo pip install -r requirements.txt
cd ..

# Rails requirements

## taglib

This is used to read ID3 tags.

Debian/Ubuntu:

sudo apt-get install libtag1-dev

Fedora/RHEL:

sudo yum install taglib-devel

Brew:

brew install taglib

MacPorts:

sudo port install taglib

## mysql

## redis

## rvm or rbenv

## ruby 2.3.1

## bundle

## Rails server setup

bundle install
config/cable.yml
config/database.yml
config/redis.yml
config/settings.yml
rake db:create
rake db:migrate
./start.sh


# Customization



DEBUG=true 

# Troubleshooting

1. No sound

* Make sure it works w/ spotify or another app
* Check the rails log. If the player says its status is 'IDLE', rather than 'PLAYING' or 'BUFFERING' then the cast isn't able to hit the web server.

# Installation: stream from outside your network

## Get an account from duckdns

## set up port forwarding



# Alternate Audio Directory

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



# Alternatives

Plex
Ampache
Subsonic
Madsonic

# Architecture

This app uses the following "stack":

1. Rails 5 for the back-end
2. AngularJS 1.6 for the front-end
3. PyChromecast to control Chromecast Audios
4. jPlayer for streaming to the browser
5. MySQL as a database
6. Redis and ActionCable (websockets) for sharing state across browsers

#### Note about the UI

Also please note that in order to keep the UI as simple as possible and allow it to work similarly across mobile devices and tablets, this project uses a CSS Flexbox layout:

https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Flexible_Box_Layout/Using_CSS_flexible_boxes

This feature is fairly new, and only works on browsers that are less than about 3 years old. It will work fine on most any desktop browser, however old phones and tablets which can no longer be updated to newer version of IOS or Android (and thus the new browsers) will just display a "Cannot display on this device" message.

