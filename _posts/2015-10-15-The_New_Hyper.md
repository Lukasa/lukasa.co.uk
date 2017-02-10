---
layout: article
title: "The New Hyper"
image:
  feature: palais.jpg
  teaser: palais-teaser.jpg
---

I'm delighted to announce that today is the release date of version 1.0.0 of
my brand new project, Hyper-h2. Hyper-h2 is the first step in what I hope will
be a long journey improving the state of HTTP in Python, by providing a set of
composable, re-usable libraries that can act as tools for building bigger and
better HTTP projects. If you want to check it out, jump straight to
[the docs](http://python-hyper.org/h2/). Otherwise, I'd like to talk a little
bit about how I got here, and about the brand-new Hyper Project that I'm going
to be working on for the foreseeable future.

## The Past

It's a little mind-boggling to realise that I first emailed
[Mark Nottingham](https://www.mnot.net/) to ask about adding my original
[Hyper](https://hyper.readthedocs.org/en/latest/) project to the list of HTTP/2
draft implementations in February of 2014. That decision has led me down a bit
of an unexpected path, including a working relationship with the IETF HTTPBis
working group and several conference talks, including one at
[The Big PyCon in Montreal](https://www.youtube.com/watch?v=ACXVyvm5eTc).
Altogether, it's been a bit of a ride.

For the past nine months or so, however, I've been dissatisfied with the shape
of the Hyper project. It suffered from some limitations that were the result of
design decisions I fundamentally believe are
[backward-looking](https://www.youtube.com/watch?v=7b4z7y6Lohw). It was also
fairly monolithic, and contained a lot of code that might be more generally
useful in the Python community. However, its greatest problem was that it was
*alone*.

Despite the fact that HTTP/2 has been being drafted for more than two years,
and that it's been a full standard since May, Python has basically had only one
HTTP/2 implementation, and it was a *synchronous client*. Additionally, there
was really no effort afoot that I could see to write any other implementation
in Python. As far as I could tell, no-one cared.

This seems unacceptable to me. Python is potentially a fantastic language to
work with HTTP/2 in. Python is especially well-suited to investigate the
potential use of HTTP/2 as an RPC mechanism (where [GRPC](http://www.grpc.io/))
is an example of one possible approach.

However, I can't write all the possible HTTP/2 implementations in Python. I'm
just one person. Nor should I: there are lots of great HTTP-using tools in
Python, and I'm not interested in trying to replace or obsolete them. Instead,
I'd like to *improve them*.

With this in mind, I set out to build the Hyper Project.

## The Hyper Project

It seemed to me that the problem was that HTTP/2 is complex. It has a framing
layer, a compression layer, a protocol stack, a priority tree, and all other
kinds of weirdness that implementations would have to write from scratch. This
is hard, and lots of developers simply didn't have the time or inclination to
do that work from nothing. What these developers need is a *toolkit*.

*(As an aside, this problem applies in the rest of the OSS world as well. You
might be surprised to know that most OSS implementations of HTTP/2 are actually
built on top of one code base: [nghttp2](https://nghttp2.org/). For example,
curl and the Apache Web Server are both built on top of it.)*

When you want to bring HTTP/2 to your platform or project, you don't want to
have to implement all of that stuff. Some of it isn't too hard but just a fair
lot of work (e.g. framing), while some of it is fiddly and prone to subtle
bugs. Regardless, it would make your life easier if you were able to pick up
one or more ready-made, off-the-shelf implementations that you can simply plumb
into your project however you see fit.

Enter the Hyper Project. The goal of this project is to provide a collection of
tools for building HTTP/1.1 and HTTP/2 implementations. Each of these tools
will be targetted at the broadest possible use-case, and will compose together
to allow you to build complete HTTP/2 implementations. They will also function
well on their own: this means that people who need something unusual or
different in one small aspect of their implementation can use the standard bits
every where else, and only hand-code the bits that they do differently to
everyone else.

There is really no reason to spread our work across a number of different
software projects, all reinventing the same wheel in subtly different ways. It
should be possible for most of the Python world to build on the same set of
common code, differing only where we need to in order to express our different
goals and opinions.

Excitingly, this isn't just a pipe dream for me: the Hyper Project exists,
right now. You can find it at [the project website](http://python-hyper.org),
which also hosts documentation for the inaugural set of sub-projects. At the
moment, these include a HTTP/2 framing layer
([hyperframe](http://python-hyper.org/hyperframe/)) and a pure-Python HPACK
implementation ([hpack](http://python-hyper.org/hpack/)), necessary building
blocks of any HTTP/2 implementation. Both of these were ripped out of the
original Hyper code and made general enough to be used elsewhere, and installed
by themselves. It also contains a CFFI-based wrapper to the
[Brotli](https://en.wikipedia.org/wiki/Brotli) compression algorithm
[reference implementation](https://github.com/google/brotli)
([brotlipy](http://python-hyper.org/brotlipy/)), as proof that the Hyper
Project is about HTTP *in general*, and not just HTTP/2.

## Hyper-h2

The crowning jewel of the current Hyper Project, however, is the fact that it
contains a general, pure-Python HTTP/2 stack, called
[Hyper-h2](http://python-hyper.org/h2/). This stack has a lofty aim: to be the
base layer for the vast majority of Python HTTP/2 implementations. To that end,
it has a number of unusual features that are worth explaining.

Firstly, and most notably, Hyper-h2 does *absolutely no I/O*. It exists
entirely in memory, reading to and writing from in-memory buffers. The reason
for this is that it becomes possible to use this same kernel of code in any
programming paradigm. If you like synchronous code, that'll work. If you like
threads, that'll work too. If you like gevent, that's fine. Twisted? Check.
Tornado? All good. asyncio? You bet. All you need to do is write the bit around
the outside that does the boring stuff of reading from and writing to sockets.
Pass the data into hyper-h2, and it'll parse it and turn it into something you
can actually work with.

That's the next notable thing about Hyper-h2: it's not a complete
implementation, like Apache or curl. Instead, it's intended to be a core part
of your implementation. Hyper-h2 lets you decide what you want to do on the
connection, and tells you what the other side did, but it doesn't know
everything there is to know about your HTTP/2 application. This means it's not
a client, or a server: it's a tool for *writing* clients and servers. Hyper-h2
enforces the HTTP/2 state machine, manages settings and compression,
serializing and deserializing, and stream management: but it doesn't do
anything about requests and responses. That's up to you: to decide what works
best for you.

This flexibility means that Hyper-h2 can be used as the base for any number
of projects. If you want HTTP/2 in `aiohttp`, Hyper-h2 could be used there.
Twisted? Same deal. And if you want to do something more specialised, embedding
HTTP/2 directly in your application, you can do that with Hyper-h2 as well.

Hyper-h2 aims to be general enough that the majority of projects could use it
without adjustment, but specific enough that it manages to be useful. Thus,
some use-cases are likely to remain out of scope for it. For example, it will
almost certainly confine itself to strictly enforcing the HTTP/2 state machine:
this means that it may not be a good choice for implementations that
occasionally need to violate that state machine.

## Success

So, what does success look like for the Hyper project? The goal is for other
projects to save time by building on top of our work, and from that perspective
we're already well on the way. hpack has already been packaged by
[Debian](https://packages.debian.org/sid/python/python-hpack) (and so by
extension [Ubuntu](https://launchpad.net/ubuntu/+source/python-hpack)),
[Arch](https://www.archlinux.org/packages/community/any/python-hpack/), and
[Kali](http://git.kali.org/gitweb/?p=packages/python-hpack.git;a=summary). This
is because hpack has been adopted by
[netlib](https://github.com/mitmproxy/netlib), the networking library for the
awesome [mitmproxy](https://mitmproxy.org/) project. Hyperframe appears to be
on the way to being a part of netlib as well, which suggests it'll be next on
the list.

From my perspective, this is already a success: we've saved a great project
some time and effort in their implementation. But we can do more.

In the next few months I plan to start pushing forward with Hyper-h2. I aim to
add HTTP/2 support to Twisted. I am also going to start accepting offers from
other projects that would like help adding HTTP/2 to their list of features by
using Hyper-h2, or by using hpack or hyperframe directly. I intend to add even
more projects to the Hyper umbrella: an interesting next target would be a
library that implements the fiendishly complex HTTP/2 priority scheme.

Additionally, I plan to rip the heart out of the old Hyper implementation and
replace it with Hyper-h2. When I do so, I'll bring that library under the
umbrella of the Hyper Project as well, which will fix this slightly tricky
naming problem we have with two different things called "hyper".

Most importantly though, it's an exciting time to be working in HTTP in Python,
and I want you to be a part of it. If you have ideas for how to enhance any of
these projects, I want to hear from you. If you have ideas for a project that
you think would be a useful part of the Hyper umbrella, I want to hear from
you. If you want to get started in Open Source and want somewhere welcoming to
get started, I want to hear from you. If you have a HTTP project you don't want
to maintain any more, I want to hear from you. And if you're interested in
learning more about HTTP, I *definitely* want to hear from you: I can't
maintain all of these libraries on my own!

I'm looking forward to the next few months working with all the great people
already involved with Python HTTP: come join me and let's build awesome stuff
together.
