---
layout: article
title: "HTTP/2 Picks Up Steam: iOS 9"
comments: true
image:
  feature: palais.jpg
  teaser: palais-teaser.jpg
---

I discovered something very exciting yesterday:

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">Having just tested in the new Xcode, I can tell you that iOS supports HTTP/2, not just in Safari but also in apps.</p>&mdash; Cory Benfield (@Lukasaoz) <a href="https://twitter.com/Lukasaoz/status/608672493713395712">June 10, 2015</a></blockquote>

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">iOS9’s advertised ALPN tokens are: h2, h2-16, h2-15, h2-14, spdy/3.1, spdy/3, http/1.1</p>&mdash; Cory Benfield (@Lukasaoz) <a href="https://twitter.com/Lukasaoz/status/608672611908874241">June 10, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

This, along with the discovery made by others that mobile Safari on iOS is also HTTP/2 enabled (unsurprisingly) is going to bring us into a brave new world for HTTP/2.

To be clear, Apple has enabled HTTP/2 for *all* HTTP done using `NSURLSession`. It's on by default, no settings need to be changed, and a quick skim through the documentation didn't turn up any relevant settings (though I'm sure there are some). Basically, what this means is that every iOS 9 application is going to be HTTP/2 enabled *by default*. Woah!

By itself this would already be massive, but Apple have gone one step further and provided [App Transport Security](https://developer.apple.com/library/prerelease/ios/releasenotes/General/WhatsNewIniOS/Articles/iOS9.html). This essentially makes HTTPS the default for all apps: you need to *specifically request* exemptions from that policy in order to do plaintext HTTP. This is a super-feature, because HTTPS on iOS 9 also defaults to a security level best described as "awesome": TLS 1.2, cipher suites with [Perfect Forward Secrecy](https://en.wikipedia.org/wiki/Forward_secrecy), and [certificate transparency](http://www.certificate-transparency.org/) for detecting incorrectly issued certificates. Apple also *claims* that their TLS handshakes will not allow downgrade to weaker settings than this, though I've yet to actually try that out in any way.

These two changes together mean that every single iOS 9 device will be doing HTTP/2 where possible from mobile Safari *and* potentially from many of their applications. This is clearly a massive incentive for app authors to deploy HTTP/2: not only will their apps be able to do it with no extra work, but they have to upgrade to newer versions of their TLS libraries on the server *anyway* in order to support the super-secure HTTPS that Apple want to do.

We're shortly going to see the power of a single platform deciding to adopt a shiny new technology. The last numbers I saw had Apple estimate that more than 80% of active iOS devices had upgraded to iOS 8, and every single one of them will be a valid upgrade target for iOS 9 (as iOS 9 supports all iOS 8-capable devices). Some vaguely reasonable guesses on the number of iOS devices in use is in the 500 million devices area, but the count is possibly much higher (remember, users may have multiple iOS devices that they use: I certainly do).

If we grant that estimate, and assume that some people don't upgrade to iOS 9 because they're lazy or scared (let's assume a negative 80% upgrade rate), then we can expect to see 320 *million* new user agents capable of doing HTTP/2 in the next few months. It's hard to get an idea of what the current usage level of HTTP/2 is in absolute numbers: [Daniel Stenberg provided](http://daniel.haxx.se/blog/2015/03/31/the-state-and-rate-of-http2-adoption/) numbers that suggest that we'd already got upwards of 5% of the traffic on the web upgraded to HTTP/2. However, 320 million user agents offering HTTP/2 is a huge incentive to web developers to upgrade.

And that doesn't even *begin* to cover the incentive on app developers. Places like Facebook, Instagram *et al.* are almost certainly going to roll out HTTP/2 support if 40% of their market is going to become HTTP/2 enabled. Why wouldn't they: the gains are compelling.

Moves like this are exciting, because they demonstrate that Apple is committed to the future of the web. They're committed to security, they're committed to efficiency, and they're committed to ensuring that their developer ecosystem moves right along with them. With all due respect to [Troy Hunt](http://www.troyhunt.com/), whose work I love, it's my belief that this will make it far harder for him to show how terribly mobile apps leak information, because they *won't leak it any more*. And while we're moving this way, I'm looking forward to a new wave of HTTP/2 debugging tools as application developers need to start rolling it out to their platforms.

HTTP/2 is about to get a massive boost in adoption, and I couldn't be more excited. Well done Apple.
