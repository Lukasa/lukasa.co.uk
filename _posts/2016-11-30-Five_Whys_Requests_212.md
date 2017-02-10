---
layout: article
title: "Five Whys on Requests 2.12"
image:
  feature: palais.jpg
---

Every now and then on big open source projects we have releases that seem to be particularly troubled. Some decision we made breaks a whole bunch of people's code, and then each fix we attempt to make produces new, unforseen problems. These releases can be very dispiriting for project maintainers, because they make it seem like every time we try to improve something we get stuck on the mistakes our past selves made.

Requests has had a few of these in the past, and right now we appear to be in the middle of another one. So far the 2.12 release series has caused problems for a number of users, and most of the attempts to fix them have caused follow-on problems.

For the sake of transparency, I'd like to do a public "five whys" post-mortem on these issues. It's admittedly tricky to do a *post*-mortem on something that is still ongoing, but there's a decent amount of technical detail and background that it might help people to understand. So, without further preamble, here we go. I'm going to start with the *current* problem, being tracked in [Requests issue #3735](https://github.com/kennethreitz/requests/issues/3735), but it's the nature of five whys that we will cover the entire train.

Unlike your regular "five whys" debugging session, however, I'll go into quite a lot of detail at each stage. This is intended to provide some technical background to the decision making, as well as justification. Ideally this will be interesting enough even if you don't really care about Requests.

So, without further preamble, let's get started.

## Five Whys

*Problem*: The current release of Requests, v2.12.2, breaks anyone who uses a URL with a scheme that isn't "http" or "https" and who passes the `params` keyword to a Requests URL.

*Why?*

In v2.12.2 we stopped doing any processing of URLs that use a scheme that isn't "http" or "https". This processing includes adding parameters to URLs. Previously we had rejected most URLs of this form (e.g. if you had a URL with the scheme "ftp", we haven't been processing that since v2.1.0), but any scheme that began with the four characters "http" would still be processed. We changed this to specifically require "http" or "https".

*Why?*

We had a problem with non-HTTP schemed URLs where we would attempt to IDNA-encode whatever we could find as a hostname. These kinds of URLs often didn't have proper hostnames, so we'd try to IDNA-encode whatever random crap we saw in roughly the hostname part of the URL. Naturally, this failed vastly more often than it succeeded.

*Why?*

Historically, this didn't fail. However, in Requests v2.12.0 we changed from using IDNA2003 to encode URLs to encode IDNA2008. The IDNA2008 encoder we are using is *much stricter* than the previous one. This meant that most things that are not hostnames do not safely IDNA encode.

*Why?*

IDNA2008 is the updated version of IDNA. IDNA, which stands for *Internationalizing Domain Names in Applications*, is a scheme that allows people to use domain names using their specific local scripts, despite the fact that the domain name system (DNS) only uses ASCII. Specifically, IDNA translates a domain like "ουτοπία.δπθ.gr" to "xn--kxae4bafwg.xn--pxaix.gr".

IDNA does this by using a scheme called "Punycode". Punycode is basically just a magic way to translate a string contaning Unicode code points outside of the ASCII range into a string consisting only of code points in the ASCII range. This is a bit like base64-encoding: we're mapping a wide range of inputs into a much smaller range of outputs. The decoding algorithm here is moderately complex and well worth digging into, but sadly outside the scope of this post.

While IDNA2003 is very widely used, IDNA2008 updates the specification in a number of ways. Specifically, it makes the following kinds of changes:

1. It disallows an *enormous* number of characters that used to be valid. According to the [official site](http://unicode.org/faq/idn.html) it disallows eight thousand such characters, including "all uppercase characters, full/half-width variants, symbols, and punctuation". For example, "http://☃.com" is a valid URL in IDNA2003 (it's "http://xn--n3h.com"), but it is not valid in IDNA2008 (this is unquestionably more *boring* than IDNA2003, but probably for the best).
2. It changes the translation of four specific characters, of which only two are really important: "ß" (LATIN SMALL LETTER SHARP S U+00DF) and "ς" (GREEK SMALL LETTER FINAL SIGMA U+03C2).

So why did we move to IDNA 2008? Well, in part because it's the newer, more correct way of doing things, but mostly because it's mandatory for the `.de` ccTLD (country-code top-level domain). This is for many complex reasons most of which have to do with cultural norms in various parts of the world: for example, IDNA2003 used to map ß (the Germanic eszett) to "ss", but IDNA2008 maps it to "zca" in Punycode (that is, as its relevant unicode code point). This change was motivated in large part by recent reforms in the German language.

Suffice to say, IDNA2008 is a complex thing. Ultimately, however, it is important for us to use whatever the TLD registries are using: otherwise, it becomes possible for users to accidentally visit the wrong site. This is a real risk, and was what we wanted to ameliorate.

*Why?*

What this "why" actually applies to is a bit unclear, so let's say that it is: "why does Requests do IDNA at all?"

Ultimately, this is about remembering that the world is bigger than the algophone part of it. Requests users all around the world deserve the right to be able to access the web using their script of choice, without being forced to understand the way Unicode works. It has been said that the best products are a collection of small joys, and for non-English speakers the fact that "http://ουτοπία.δπθ.gr" *just works* is a huge advantage.

Ultimately, Requests is a project that cares about the whole world, not just the part of it that speaks English.

## Outstanding problems

Ultimately, our current issue comes from the fact that we have been inconsistent on our stance regarding URLs with weird schemes. Way back in v2.1.0 we merged a patch that allowed URLs with schemes that were not "http" or "https" to essentially opt-out of our URL manipulations. We wouldn't try to parse them or understand them in any way, let alone manipulate them, we'd just pass them through to the lower levels of the stack. We really did skip *all* processing: we didn't even normalise the type of the URL, it could be either `bytes` or `unicode`.

However, the way that the check was constructed was not extremely cautious. The code that was merged into v2.1.0 looked like this:

    if ':' in url and not url.lower().startswith('http'):
        self.url = url
        return

Now, this was clearly designed to account for different types of URLs. The first check (for `':' in url`) is designed to ensure that a URL that doesn't appear to have a scheme in it at all is ignored: if we can't work out what the scheme is we clearly have no idea what is going on. The second check is designed to check for "http" and "https" in one check.

Unfortunately, that looseness meant that any scheme that *began* with the four characters "http" would get processed as though it were HTTP. Some downstream users wanted to opt-in to this behaviour, and so would deliberately construct non-HTTP schemes that met this form: two notable ones are "http+docker" and "http+unix".

However, these schemes may have no hostnames, or worse, have hostnames that are not IDNA2008 valid. Those users were broken by the move to IDNA2008 with its much stricter validation, so we wanted to attempt to give them an escape-hatch. One of the ways we did this was to tighten up that check, to explicitly look for the two schemes we support. This meant that those users who had constructed URL schemes that attempted to walk this narrow line of being processed like HTTP URLs without actually *being* HTTP URLs lost their processing of query string parameters. Naturally, these users weren't delighted with this change.

The current proposal I am putting forward is to deliberately reinstate the weaker check, and to hope that the other patches we added to tolerate domain names that do not correctly encode in IDNA2008 are sufficient to cover these users. Ideally, that will lead to us getting a v2.12.3 out the door fairly swiftly that is finally in decent enough shape to be the "first good release" in the v2.12 series.

## TL;DR

I dunno. I put this up mainly as a brain dump to help people see what we're dealing with right now, and to help people get insight into the kinds of maintenance work that goes on in large projects. In particular, with projects as large as Requests there is *no* corner of the codebase that is not exercised by at least one of your users. That means that any change you make needs to be right the first time, because if you find that your code was too lenient you will inevitably break people when you want or need to tighten it up. Remember: you can always make checks *less* strict without breaking running code. You cannot make checks *more* strict without risking breakages.

I guess if there is anything to learn from this it is that you should go give your friendly neighbourhood maintainer a hug.
