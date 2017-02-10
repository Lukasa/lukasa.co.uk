---
layout: article
title: "Certifi: The State Of The Union"
image:
  feature: palais.jpg
---

Shortly I'll be pushing out a new release of the excellent [certifi project](http://certifi.io/en/latest/). This will be certifi's first release in a little while, and I want to explain why it took so long and what's happening over the next few months.

## 1024 Bits Ought To Be Enough For Anybody

Last year, Chrome and Firefox decided to forcibly remove all 1024-bit root certificates from their trust stores. This is for security reasons: both projects security experts were quite rightly concerned about the security of those certificates in the modern era.

Many CAs were affected by this, as they'd been issuing certificates signed by their 1024-bit root certificates that were still valid. This represented a problem for them and their customers, as they'd potentially need to reissue many many certificates signed by their new 2048-bit roots.

Worse, those new certificates would not be trusted by users with older browsers, because those users wouldn't have the new 2048-bit roots in their trust stores. That would be really bad.

For that reason, many CAs used so-called *cross-signed roots*. I'm not going to go into detail on exactly how these work, but suffice to say it allows for browsers to build one of two trust chains. The first terminates at the 2048-bit root if it's present, but if it isn't the browser will follow the path one step higher up and find the 1024-bit root.

This works great because Firefox and Chrome use [NSS](https://developer.mozilla.org/en-US/docs/Mozilla/Projects/NSS) for their TLS. The NSS library has a number of interesting features, but in this case it has the ability to trust certificates that are not self-signed, such as these new cross-signed roots.

OpenSSL cannot do that in any version earlier than 1.0.2, which is not widely deployed.

This meant that, when Mozilla removed the 1024-bit roots from their trust store, OpenSSL immediately started rejecting certificates because it was unable to build a trust chain. This broke a ton of people, and requests shipped a whole special release that did nothing but step back to the old cert bundle.

## The Plan

This is the first release of certifi since that happened, and it also marks a watershed moment: it's the first release of certifi that is not just a translation of Mozilla's cert bundle.

We've painstakingly gone through Mozilla's bug tracker and located every 1024-bit root that they removed. We've retrieved them, and then added them back into the most recent certificate bundle. As of today we'll be shipping a version of certifi that contains this mutant hybrid bundle.

This is a compromise decision. This new bundle is weaker than Mozilla's default bundle (which does not contain the old roots), but it shouldn't immediately break all your stuff. It's less than ideal, but shipping a wildly out-of-date certificate bundle is worse.

We're also beginning a planned deprecation of these root certificates. Please be warned: from this point onwards, cross-signed certificates are on borrowed time.

At the end of May, a new certifi bundle will be released that contains two bundles: one without 1024-bit roots, and one with them (the current bundle). By default, the more secure bundle will be used, but we will have a fallback option for users that desperately need it. At this point, however, using the fallback will generate deprecation warnings.

At the end of September, we will release a new certifi bundle that no longer contains the 1024-bit roots. At this point, any site continuing to use a cross-signed root certificate will fail trust verification when used with the certifi bundle.

We believe this represents the best compromise between user-friendliness and security. It's our desire to avoid breaking user code unnecessarily, and we hope that this gradual transition will help users put pressure on service providers to use newer certificates.

## Other Stuff

From this point onward, certifi will also be building up its infrastructure to provide more frequent releases and better reporting about whether or not certain sites are trusted in the released bundles.

Please let us know if you have feedback or thoughts about certifi, we'd love to hear your thoughts!
