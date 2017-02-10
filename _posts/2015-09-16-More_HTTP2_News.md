---
layout: article
title: "More HTTP/2 News"
image:
  feature: palais.jpg
  teaser: palais-teaser.jpg
---

Just a short one today folks. I wanted to indicate some exciting stuff that's
happened in the past few hours, and get you excited for how the web is shaping
up.

A few months ago I wrote a post about how iOS 9 was going to have HTTP/2
support, which you can [find here](https://lukasa.co.uk/2015/06/HTTP2_Picks_Up_Steam_iOS9/).
Since then, I started work on my new ambitious project: a pure-Python HTTP/2
stack that would work equally well as a client or a server. You can find this
project [on GitHub](https://github.com/python-hyper/hyper-h2).

For the moment the project ships with a basic example server, written for
Twisted. This server does nothing much: if you hit the base path, it echoes
back a JSON dictionary of the headers from the request. Very simple.

Today, iOS 9 came out for real, and I decided I'd play around with it a bit.
Using a custom version of Twisted containing [a patch to enable ALPN](https://twistedmatrix.com/trac/ticket/7860),
I made a few tiny changes to the Twisted example server to get it up and
running with TLS and a self-signed certificate.

The result is below: a series of pictures of modern web browsers speaking
HTTP/2 to a HTTP/2 server written entirely in Python. There's no C extensions
here: just Python. Along with each image is the list of settings that HTTP/2
client explicitly sends.

The next few months of work on hyper-h2 should be really interesting. Come help
me out! In the meantime, if you want to try it out yourself, the code is
available [here](https://github.com/python-hyper/hyper-h2/tree/ios_fun): don't
forget to apply the Twisted patch!

### Safari (iOS 9)

![Mobile Safari, iOS9](/images/mobile_safari_h2.png)

Settings:

- `SETTINGS_HEADER_TABLE_SIZE`: 4096
- `SETTINGS_ENABLE_PUSH`: 0 (this is sad: no server push for mobile Safari)
- `SETTINGS_MAX_CONCURRENT_STREAMS`: 100
- `SETTINGS_INITIAL_WINDOW_SIZE`: 65535

### Safari (OS X El Capitan GM)

![Desktop Safari](/images/safari_h2.png)

Settings:

- `SETTINGS_HEADER_TABLE_SIZE`: 4096
- `SETTINGS_ENABLE_PUSH`: 0 (No push for desktop either? Double sadness!)
- `SETTINGS_MAX_CONCURRENT_STREAMS`: 100
- `SETTINGS_INITIAL_WINDOW_SIZE`: 65535


### Chrome (Version 45.0.2454.85, OS X)

![Desktop Chrome](/images/chrome_h2.png)

Settings:

- `SETTINGS_MAX_CONCURRENT_STREAMS`: 1000
- `SETTINGS_INITIAL_WINDOW_SIZE`: 6291456

### Firefox (40.0.3, OS X)

![Desktop Firefox](/images/firefox_h2.png)

Settings:

- `SETTINGS_INITIAL_WINDOW_SIZE`: 131072
- `SETTINGS_MAX_FRAME_SIZE`: 16384
