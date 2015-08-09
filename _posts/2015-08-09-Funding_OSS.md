---
layout: article
title: "Funding OSS"
comments: false
ads: false
image:
  feature: palais.jpg
  teaser: palais-teaser.jpg
---

It's time to have a conversation, folks.

At PyCon AU this year, Russell Keith-Magee just gave an extremely interesting
talk about [the difficulty of funding OSS sustainably](https://www.youtube.com/watch?v=mY8B2lXIu6g).
I recommend watching that talk before reading the rest of this post if you have
the time.

Russell's talk ends with something of a call to arms: he wants the community to
start talking about how we can more sustainably fund open source software. He
explicitly asks people not to ask questions of him: instead, he wants a
dialogue. I agree with Russell: I think Open Source is at real risk

This blog post is my contribution to that dialogue.

*Author's Note: Like Russell, I also don't want direct feedback on this post,
so I have disabled comments. If you want to say something, please post it
yourself (either on a blog or social media) and ping it to me. We need to have
this conversation properly, and get everyone involved.*

## Hypothesis

<blockquote class="twitter-tweet" lang="en"><p lang="en" dir="ltr">Effective immediately, there will be no further feature development on Hypothesis for the foreseeable future. <a href="http://t.co/09MsjhYakH">http://t.co/09MsjhYakH</a></p>&mdash; David R. MacIver (@DRMacIver) <a href="https://twitter.com/DRMacIver/status/630076877680582656">August 8, 2015</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

David MacIver has decided to [abandon further feature development](http://www.drmaciver.com/2015/08/throwing-in-the-towel/)
on the excellent [Hypothesis](https://hypothesis.readthedocs.org/en/latest/)
library. This is extremely unfortunate: Hypothesis is one of those great
examples of someone porting a simple idea into Python and turning it into a
best-in-class version of the tool (a good summary of Hypothesis is
["QuickCheck for Python"](https://hackage.haskell.org/package/QuickCheck)).

This, while tragic, is hardly new. Generally speaking, getting funding for OSS
is extremely hard. Most projects struggle for funding and resources, even big
'professional' projects like Django. When it comes to smaller ones, run by an
individual or a small team (Hypothesis, Requests), it's often even harder to
get sustainable funding for the work, despite the amount of value it returns.

## Tragedy Of The Commons

This, as Russell points out, is a tragedy of the commons. Open Source and Free
Software provides enormous value to the world, both economic and social.
However, the value that it provides rarely makes its way back to those doing
the work. This causes *so* many problems. It causes us to lose motivated,
talented engineers. It's also a major contributing factor to the relative lack
of diversity in the OSS community: you can only really get involved in OSS if
you have the time and wealth to do it for free (or almost for free), and it
turns out that time and wealth are disproportionately possessed by the young,
white, middle-class, and male.

It's extremely hard, in a world where startups get billion dollar valuations,
to see the developers who build the tools they use get shafted. Let's take
Uber as an example. Now, a warning: I don't particularly begrudge Uber their
success. They have lots of problems, but those problems are not the subject of
this post.

So, Uber. They were recently valued at more than [$50 billion](http://www.wsj.com/articles/uber-valued-at-more-than-50-billion-1438367457),
by means of a seed round in which they raised *$1 billion* in capital.
According to [StackShare](http://stackshare.io/uber/uber), Uber uses Python
as part of their work. So, let's pose the question: how much Python OSS does
Uber use?

Quite aside from Python itself (which has never seen a dime of Uber's money as
far as I know), the odds that they use [Requests](http://docs.python-requests.org/en/latest/)
are *pretty damn high*. But to the best of my knowledge they have never, ever,
contributed any money to fund the ongoing maintenance of Requests. Not a dime.
And this is one project amongst the many hundreds they inevitably use.

All reasonable estimates point to the idea that Uber CEO Travis Kalanick is
probably a [paper billionaire](http://www.forbes.com/sites/stevenbertoni/2014/06/06/uber-ceo-kalanick-likely-a-billionaire-after-18-2-billion-valuation/). Now, I'm sure he and his team (let's be honest, mostly his
team) have contributed the bulk of the $50 billion of value they apparently
have. However, is it too much to pretend that maybe, just maybe, the OSS
community provided some too?

If Uber paid just 1% of their *one billion dollars* back into OSS, that would
be ten million dollars. Ten million dollars would fund 60 developers for a year
at crazy Valley salaries: more like 100 if they took a pay cut! Can you imagine
the value that would enter the ecosystem if Uber stepped up and did that? 60
developers working *full time* on the software that we all rely on for a whole
year would be game changing.

## Companies Have To Step Up

Right now there's no other way to put it: most companies are exploiting open
source developers. In this regard, at least, Stallman was right.

This is not true of all companies. For example, HP funds several developers to
do OSS Python work upstream of OpenStack. This includes paying Donald Stufft to
work full-time on Python packaging, and as of next month will also include
paying me to work full-time on Python HTTP projects (like requests).

However, this is unusual, and most companies don't give anything like enough
back. I agree with Russell: this is the next major struggle for open source
and free software. Right now a very small number of developers have their work
funded: most do not. This needs to change, both for the sake of our open source
developers and because it's the right thing to do.

So, let's get started. Big companies, especially those with lots of funding,
consider whether your success is built upon the unpaid work of others. If it
is, reach out to them and see if you can fund them. It's in your best interest.
