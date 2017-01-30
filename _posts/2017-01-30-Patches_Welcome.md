---
layout: article
title: "Patches Welcome"
comments: true
ads: false
image:
  feature: palais.jpg
  teaser: palais-teaser.jpg
---

For the last 18 months I have been a full-time Open Source Software maintainer. Since starting that role I have taken over the major maintenance work for upwards of 10 software projects, with a cumulative monthly download count somewhere near the millions. In calendar year 2016 I received 15,000 emails from GitHub, despite religiously unsubscribing myself from repositories where I have the commit bit but no major maintenance responsibility.

I say all this not to brag, but to explain something. When going through the issues lists on projects I maintain, you may occasionally see me type something like "I'll merge a pull request with that fix in it". This comment comes in response to someone else suggesting a fix for an issue, or occasionally an enhancement. I will do it when someone has suggested a fix that seems correct, and is also relatively simple and self-contained.

My primary reasoning for doing this is very simple: if I wrote fixes for all of these issues I'd have no time to work on anything else. I'd be unable to work on larger features without sacrificing my free time, which is already proscribed by the nature of OSS work (I spend a lot of my "free" time responding to emails and reviewing patches, primarily to work around time zone issues). This would be a recipe for extremely rapid burnout.

But people have rightly asked how this is any different from maintainers uttering the dreaded phrase "patches welcome". To many, this phrase is dismissive and full of disdain. To explain how I try to avoid the "patches welcome" syndrome, I first need to explain a little bit about what it is.

## I Don't Care About Your Problems

The phrase "patches welcome" is, of course, not inherently problematic. In almost all OSS projects patches are literally welcome. In many senses it can be a stand-alone sentence with no baggage at all: a mere statement of fact.

However, the phrase has got a dark side. This dark side comes from its regular deployment by OSS maintainers or third parties in response to feature requests or criticism. For example, a not-uncommon interaction in the OSS community is:

- *User*: This feature doesn't work on Windows.
- *Developer*: Patches welcome.

"Patches welcome", in this case, is a code-phrase. In this context, it means "I don't care enough about your problem to fix it, or even to put it on a roadmap". In many cases it can even mean "I don't really acknowledge this as a problem worth fixing, but if you fix it then I will merge that patch I guess".

Worse, however, is the fact that this phrase also implicitly says "If you don't have the skills to fix your problems yourself, you don't deserve to have them fixed at all". It is another example of what Aurynn describes as [contempt culture](http://blog.aurynn.com/contempt-culture): it is, once again, programmers prizing the ability to code above all else.

Naturally, deployed like this the phrase *is* dismissive: I don't think anyone would reasonably disagree. It's an attempt to end the conversation by saying that the maintainer will not help you, and that you must help yourself.

## Consider The Maintainer

Now, to be clear, I believe that maintainers *absolutely have the right* to say "this is not important to the project so I will not accept it". Like Jess Frazelle, [I believe maintainers should say "no" a lot](https://blog.jessfraz.com/post/the-art-of-closing/). But we should try to avoid being dismissive when we do it. We shouldn't denigrate the efforts of others, or suggest that some people's problems are less important.

The problematic "patches welcome" phrase is easily replaced. It's not hard to say "Sorry, but the maintenance team doesn't have the bandwidth to address this problem right now. It's definitely a problem, and if someone can provide a fix for it we'll work with them to get it merged, but none of the regular contributors are going to be able to get to this any time soon." Hell, if you're a developer who likes using the phrase "patches welcome" you should consider binding that entire quote to a keyboard macro so it inserts itself instead of "patches welcome".

Because, sadly, now that "patches welcome" has obtained the air of being dismissive, it is frequently *deliberately* deployed to be dismissive. This is terrible when it is done to someone you don't know, though it is also a frequent source of jokes amongst OSS folks who *do* know each other (I have found "patches welcome" to be a good response to people who sarcastically complain about things 😉). But the fact that some people use it to denigrate and dismiss is reason enough to try to replace it with something better, something that indicates that you aren't saying "no" because you don't care, but because you don't have the bandwidth to process it.


## I'll Merge This

So back to my favourite maintainer phrase. Why is saying "I'll merge a patch like that" different from saying "patches welcome"?

As with so many things, the answer is all about context. Firstly, let me note that I actually have two variations on that phrase. The short one is "I'd merge a PR with that fix", and the long one is "That fix looks right: are you interested in opening a PR with it? I'd be happy to merge it." The former is reserved for regular contributors to projects, people who I know are not intimidated by the idea of contributing to the project. The latter is for people I don't recognise, but it's also the key to understanding why I think this phrase is different.

You see, this is all about *granting permission*. This phrase is always deployed once someone has identified a fix already. I am saying, essentially, "you have understood the problem and the solution, and if you would like to provide the fix to that problem I give you permission to do so".

This is a key difference. I am not trying to tell you to go away, or to do all the work. I am instead saying that I agree with your assessment, and will enable you to provide that fix. I am agreeing that the problem exists, and that the solution to that problem is acceptable to the project at large.

The repurcussions of taking this attitude to smaller fixes is profound. The goal is to quietly, politely, suggest to others that they have successfully solved this problem in their heads, and that I will help them solve this problem in the code. I am inviting them to contribute, to be an even bigger part of the project. I am, in essence, inviting a user to become a contributor.

In this model, everybody wins. By granting permission I am lowering the barrier to entry to the project. Simultaneously, I am removing one further task from my plate: if someone else writes this patch, I don't have to. This doesn't necessarily reduce my workload in the short term: patch review can often be more time consuming than patch authorship, though for smaller patches that's not so likely. But in the long term it has the possibility of giving someone an easy entry into the world of contributing to my projects.

There are many people who are capable of helping out with OSS, but who are afraid to do so. Those people often need *permission* in order to get the courage to help out. If someone has summoned the courage to suggest a fix for an issue, and they're right, show them that you trust them by asking them if they'd like to take the next step.

And if they say no? Well, you're no worse off than before.