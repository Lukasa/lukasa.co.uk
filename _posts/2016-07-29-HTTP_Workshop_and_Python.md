---
layout: article
title: "The HTTP Workshop and Python"
image:
  feature: palais.jpg
---

From the 25th to the 27th of July this year, I was in Stockholm, attending the [2nd HTTP Workshop](https://httpworkshop.github.io/). This event, a (so far) annual gathering of some of the leading experts in HTTP, is one of the most valuable events I've ever had the fortune to attend. Given that I was attending the event at least in part as a representative of the Python community, I thought it'd be good to share some of my thoughts and opinions in the wake of this event with that community.

But first, let's talk about the event itself. When pressed I've described the event as a "conference", but that's not really an accurate portrayal. 40 people attended, and basically spend three days with all 40 of us sat in the same room discussing HTTP. We had a loose framework of sessions to kick discussions off: some people shared data they collected, others shared insights they'd gained during implementation of HTTP/2, and still others (cough cough Google) talked about the ways in which we could push the web forward even further.

These sessions were mostly just a starting off point, however. Conversations were allowed to flow naturally, with different participants asking questions or interjecting supporting material as the discussion progressed. These discussions were almost inevitably of both high value and very dense informational content: with all the attendees being experts in one or more aspects of HTTP in both theory and practice, there was a phenomenal opportunity to learn things during these discussions.

## Attendees

40 people showed up to the workshop, and they can be fairly neatly divided into two groups. The first group came from the major technology companies involved in the web. For example, Mozilla sent 5 attendees, Google sent 4, and Facebook, Akamai, and Apple sent 3. There was also a long tail of big web companies that sent one or two people, including most of the obvious organisations like Microsoft, CloudFlare, Fastly, and the BBC.

The other major collection of folks represented were individual implementers, most of whom came from open source backgrounds. In particular we had a great density of some of the earliest OSS HTTP/2 implementers, from across a wide variety of implementations. We had Brad Fitzpatrick for Go, Daniel Stenberg for Curl, Kazuho Oku for H2O, Tatsuhiro Tsujikawa for nghttp2, Stefan Eissing for Apache mod_h2, and myself for Python. On top of that we had a series of other HTTP and HTTP/2 experts from the OSS community, like Moto Ishizawa and Poul-Henning Kamp.

There was a third, smaller group, which could most accurately be described as "observers". These were folks representing organisations and interests that were not currently heavily involved in the HTTP space, but for whom it was extremely relevant. For example, the [GSMA](http://www.gsma.com/) sent a representative.

This wide variety of attendee backgrounds ensured that the space managed not to be an echo chamber. For almost any idea or proposal, there was guaranteed to be at least one person with a well-argued position in favour, and at least one with a well-argued position in opposition. That kind of environment is great for ensuring that people come out of the discussion with a much better understanding of the *problem*, even if it doesn't always move the people on each side.

## Topics

Over the three days, we covered a lot of topics. Unsurprisingly, with 40 people in attendance, not everything was of equal relevance to each person. Rather than summarise the entire meeting, then, I'll focus on the topics that seemed like they were most relevant to the Python community and the future development of HTTP for Python web developers.

### Server Push

One of the headline discussions in the first day, from my perspective, ended up being about HTTP/2 Server Push. Several implementers from CDNs presented their data on the effectiveness of server push. The headline from this data is that it seems that we have inadvertently given web developers the idea that pushing a resource is "free", and therefore that all resources should automatically be pushed.

This is, of course, not true. While pushes *can* in principle be automatically rejected, in practice it's not always easy for a browser to know that it doesn't need a resource. As a result, server admins that push all their static resources may waste bandwidth transmitting resources that the client already has and can serve from cache, or could at least serve using an "If-Modified-Since" ⇒ 304 Not Modified dance that transfers relatively few bytes.

Worse, the win-case for server push is not as good as the lose-case. If you push an unneeded resource, that consumes all the bandwidth of that resource and gets in the way of delivering other things. On the other hand, if you fail to push that resource and the client needs it, the only cost is 1RTT of latency in page load. On many connections, that may be a *bad* trade-off, and that's especially true if your static resources are cacheable.

There is some work ongoing in the HTTP working group to provide browsers and servers tools to address this problem. For example, Kazuho Oku is proposing a specification to allow browsers to provide a digest of the resources they already have in the cache, which allows servers to only push resources they know the clients don't have. While I was lukewarm on the proposal before this meeting (it seemed like a lot of complexity to solve a small problem), with the extra data the CDNs shared I'm now strongly in favour of it: it allows us to make much better use of limited network resources.

The other remarkable problem that revealed itself during the course of the discussions were that none of the major browsers actually store pushed resources into the cache. That's remarkable, given that one of the most regularly discussed use-cases for server push is cache-priming. I got the impression from the discussion that the browsers weren't really that pleased with this state of affairs, so I wouldn't be surprised to see this change in the future.

### QUIC

![Jana doesn't like it when we call it TCP/2](/images/call-it-tcp2-one-more-time.jpg)

On the second day, Jana Iyengar from Google presented some of Google's work on QUIC. This was enormously interesting, partly because I haven't had a chance to play much with QUIC yet, but mostly because Jana's background is very different from most of the other attendees. Unlike the rest of us, whose expertise is mostly at the application layer, Jana has a transport layer background, which gives him very different insight into the kinds of ideas that were thrown around at the workshop.

QUIC is a topic I've had mixed feelings about for a while, mostly because the amount of effort required for me to implement QUIC is an order of magnitude more than the work required to implement HTTP/2. In no small part, this is because QUIC is as much a transport protocol as it is an application protocol, which means that we need to tackle things like congestion control: a much more complex topic than almost anything we face in HTTP/2. This kind of extra workload is no problem for Google, with its army of engineers, but for the open source community it represents a drastic increase in both workload *and* technical expertise required. After all, most people in the OSS community who are experts in implementing HTTP are not experts in implementing TCP!

However, as the discussion continued I became increasingly comfortable with the progress of QUIC. Fundamentally at this point, Google and the other tech giants are expending enormous engineering resources on eking ever smaller latency improvements out of the web. This is a laudable goal: a lower latency web is good for everyone, and I commend their progress. However, it's not clear that Python web servers and clients gain an enormous amount from trying to keep up.

Trying to squeeze 5ms lower latency from your network doesn't help the rendering time of your Python web page as much as optimising your Python code, or moving to a different backend language, or using PyPy. If you're running Python in your web server *and you aren't behind a CDN*, then QUIC is not your highest priority in the search for performance.

However, once your web site gets big enough to put behind a CDN, your origin server is no longer the primary way to gain performance! Happily, the big CDN providers *do* have the engineering resources to deploy QUIC relatively rapidly. For Python clients the latency gains are a bit more helpful, but again your client will likely gain more by just finding other work to do while it waits for data than by optimising the latency that much. This means that, realistically, those of us in the Python community can afford to wait until a good QUIC library comes along: we have other performance bridges to cross first.

On top of all that, QUIC is not going to be anything near as useful in data center environments where we have high-bandwidth, low-latency, good-quality networks. It turns out TCP works *great* in environments like that. Given that a large number of Python servers and clients are deployed in just such an environment, the improvements of QUIC are much less noticeable.

That means that when someone starts work on and open-sources a good QUIC library (by which I mean not the stack lifted out of Chromium, but one that exposes a C ABI and doesn't require the Go runtime, so I can bind it from Python) I'll happily bind it and make whatever changes we need to get QUIC in our Python servers and clients. I'll even do so early in the development process and provide feedback and bug fixes. But I'm not in any rush to build one myself: I don't think I've got the skill set to build a good one, and I think the time it would take me to get that skill set is better deployed elsewhere in the HTTP space.

However, I still want to see the IETF involved in the QUIC process. One way or another, Google is *going* to do things like QUIC: its business model depends on them. That means that those of us in the IETF shouldn't fight back against this kind of model just because it's not of immediate use to the long tail of the web. Instead, we should encourage Google to keep coming back: at least that way the web remains open and free, and those of us in the long tail can make sure that Google makes engineering decisions that don't close the door on us.

### Blind Caching

I don't have a lot of useful things to say here, other than it's a great idea. This attempts to solve some of the problems we have caused with forward proxies by allowing proxies to cache content in an encrypted form, which will be decrypted on the browser. This seems like a good idea.

### Happiest Eyeballs

The workshop briefly discussed the suggestion from Fastly that perhaps clients should attempt to connect to *all* of the IP addresses returned in a DNS response and use the one that connects the fastest. This is basically an extension of the Happy Eyeballs algorithm for IPv4/IPv6 to attempt to route around congested or otherwise damaged routes.

This seems like an interesting enough idea, and I suspect a browser implementer will give this a shot sometime over the next year to see how it works out. Watch this space.

### Structured HTTP Header Field Values

One of the constant sources of problems in HTTP is that there is no well-defined format for how your HTTP header field value should look. Some header fields have values that are just strings (e.g. Location), some have values that are simple comma-separated lists, others have incredibly complex parameter-based syntaxes, and still others have weirdo one-off things that don't look anything like any others (I'm looking *right* at you, `Cookie`, you monster). This means that clients and servers frequently have many one-off parsers for different header field values which all share relatively little code: bad for programmers and for web security in general, given how many of these clients and servers are written in unsafe languages.

Julian Reschke has been leading a proposal to consider a standard structure for new header field values. The initial proposal has been JSON, and that was discussed a bit at the workshop. Generally speaking the workshop seems lukewarm towards JSON, in no small part because JSON has a fairly surprising set of rules around parsing numbers. For example, the number <span style="word-break: break-all;">0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100e400</span> is treated by NodeJS' built-in JSON parser as 100, but by Ruby 2.0.0's as 0. That is likely to be somewhat problematic (understatement of the year!), and opens implementations up to nasty attacks caused by understanding a header field value differently to their peers.

However, the general consensus is that having a well-defined structured format for header field values would be an extremely good idea. Expect more work to be done here in the next year, with hopefully a draft specification coming soon. Along with a better serialization format, one can only hope!

### Debug Information for HTTP/2

The OSS implementers amongst the group also talked briefly about some of the problems that they've bumped into with implementing HTTP/2. Given that there was quite a lot of consistency across the board with the kinds of problems people bump into, this was likely to be an ongoing problem, particularly for new implementers.

The discussion progressed far enough that Brad Fitzpatrick and I decided to prototype a possible solution to the problem. This solution would allow HTTP/2 servers to essentially reveal information about what they believe the state of the connection is. This allows a number of things. Firstly, implementers of clients who find their connections failing can interrogate the server and check what the state is. Disagreeing about this state is the cause of almost all interop bugs, and so seeing what one side believes the state is allows for much more debuggability. Secondly, and just as importantly, it allows tools like [h2spec](https://github.com/summerwind/h2spec) to test implementations not just for whether they emit the correct frames and data, but also to essentially interrogate them for "thoughtcrime": it can check that the server got that behaviour right on purpose or just by accident.

This has been well-enough-received that Brad and I have written up a draft proposal for how it should work, which you can find [here](https://tools.ietf.org/html/draft-benfield-http2-debug-state-00). We've also received a lot of good ideas about further enhancements. If you want to see it live on the web, you can point your HTTP/2-enabled client or browser to either [Brad's Go implementation](https://http2.golang.org/.well-known/h2interop/state) or [my Python implementation](https://shootout.lukasa.co.uk/.well-known/h2interop/state).

Over the next few weeks I'll be pushing forward trying to get a good feel for how this looks more generally. I'll then add hooks into hyper-h2 to allow servers that want to to automatically generate this body: I may even allow hyper-h2 to automatically respond to requests for this information, with no need for server authors to do anything at all!

## Final Thoughts

This was my first HTTP Workshop, and I think it was enormously valuable. In the space of three days I learned more and gained more insights about HTTP than I have done in the previous 12 months, and I knew more than most about HTTP before I went! I'm extremely hopeful that these events continue in the coming years, and that I am able to attend the next one.

I also want to mention that it was a genuine honour and pleasure to represent the Python community at this event. Only two attendees represented language communities (Brad for Go, me for Python), and I think it's fantastic that the Python community was able to have a voice at this kind of meeting. It bodes really well for the future health of the Python HTTP ecosystem, and shows the continuing importance and relevance of the Python programming language and community.

I'd also like to thank my employer, Hewlett Packard Enterprise, who have done excellent work in supporting the Python HTTP ecosystem for the last year and who enabled me to do the work required to bring value to an event like this one. Long may it last!
