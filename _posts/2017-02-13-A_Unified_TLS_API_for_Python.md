---
layout: article
title: "A Unified TLS API for Python"
image:
  feature: palais.jpg
---

I have just proposed [PEP 543: A Unified TLS API for Python](https://www.python.org/dev/peps/pep-0543/) to the [`python-dev` mailing list](https://mail.python.org/pipermail/python-dev/2017-February/147387.html) for discussion. While the bulk of the technical correspondence will happen on that mailing list, I wanted to briefly write a long-form, less formal discussion of why this PEP is important and the problems I'm trying to address.

To understand the problem that this PEP aims to address, it's important to try to understand the approaches that different programming languages take to supporting TLS. TLS is an extremely widely-deployed network protocol and it's essential for any language that wants to be used for "real work" to have at least *some* support for TLS, if only to ensure that data can be securely retrieved from websites. That means that anyone working on a programming language eventually needs to confront a core question: "how will my users do TLS?"

Conveniently, languages can be broken more or less down the middle into two groups, which I will for inflammatory reasons call "systems languages" and "higher-level languages". This is an obviously absurd categorisation of languages[^1], but it's a simple enough division that lets us focus on intent.

For the "systems languages", which for this example include languages like C, C++, and Rust, there is a focus on simplicity and minimalism: it is necessary to be able to build binaries that assume a minimal operating environment. For these languages, TLS is considered to be a "bring your own" affair: programmers that want TLS should reach for one of the many binary TLS libraries that the world has to offer (such as OpenSSL or GnuTLS), the language will not provide one for them. In these languages, many higher-level frameworks will exist that combine these libraries with appropriate I/O management code and protocol implementations for users that don't need the flexibility of a BYO TLS approach. But it remains the case that the *language* does not privilege one TLS implementation above any other.

For the "higher-level languages", however, there is a higher focus on immediate programmer productivity. Many programmers will likely want to use these languages for providing sysadmin "glue" and other important tasks that get a great deal of value from going from zero to working as quickly as possible. For this reason, these languages are incentivised to create a "blessed" TLS implementation and API that they ship in their standard library. Python does this with its `ssl` module, Go has `crypto/tls`, Ruby has its `OpenSSL` module, and Java has `JSSE`.

These blessed implementations can be further divided into two groups: custom implementations, and bindings. `crypto/tls` and `JSSE` are both custom TLS implementations that are written from scratch in the language that uses them, while `ssl` and `OpenSSL` are both bindings (unsurprisingly, they're both bindings to the venerable OpenSSL library). In general, languages that ship bindings overwhelmingly choose to bind OpenSSL. Python is one of these languages.

Despite its name, Python's `ssl` module is not actually intended to be an abstract SSL (better called TLS) implementation. It is strictly a binding to OpenSSL. It uses OpenSSL concepts fairly directly, and frequently directly exposes OpenSSL constants and flags. This means it would be better named the `openssl` module. The module's API cannot be easily translated to work with one of the many other TLS implementations that exist.

Now, at this point it would be reasonable to say: so what? Good question.

It turns out that OpenSSL is just one of many TLS implementations in the world. It's comfortably the one with the best name recognition, and is definitely the most widely-deployed open-source TLS implementation in the world. But there are plenty of others. For example, [a quick jaunt over to Wikipedia](https://en.wikipedia.org/wiki/Comparison_of_TLS_implementations) presents the following others: Botan, BoringSSL, Bouncy Castle, cryptlib, GnuTLS, LibreSSL, MatrixSSL, mbedTLS, NSS, s2n, SChannel, Secure Transport, and wolfSSL.

While OpenSSL is a reasonable choice, there are plenty of good reasons for wanting to use other TLS implementations. For example, NSS is widely deployed in Red Hat deployments for other security purposes, and users may not want to deploy with multiple TLS stacks. Alternatively, users may want to use as much GPL'd software as possible, and so would prefer to use GnuTLS. Or maybe you're running [MicroPython](https://micropython.org/) and would like to use TLS, but don't want the massive binary size of OpenSSL and so would prefer something like mbedTLS instead. These are all excellent reasons to want to use alternative implementations.

But far and away the most common reason to want to use an alternative implementation is to write user-facing software that feels "platform-native". This is a complex notion that ultimately boils down to: if I installed my software-vendor's preferred web browser, and browsed to this URL, I should get the same result in the Python code as I do in the web browser. For Linux operating systems that usually means using OpenSSL, but can sometimes mean using GnuTLS or NSS depending on the OS in question. For Mac users, that would mean using Secure Transport, and for Windows users, it would mean using SChannel.

However, Python ultimately provides no tools to do this in a general way. While there are tools to use these other libraries, such as Will Bond's impressive [oscrypto](https://github.com/wbond/oscrypto) library, there are no tools available to Python that allow people writing applications to write to a *generic* TLS API that can be implemented by a number of TLS backends. This leads to a surprising number of real problems. A short list of them includes:

1. It becomes very hard to write "native apps" for many platforms. On Linux it's mostly OK, if you restrain your definition of "Linux" to include "systems that use OpenSSL as their default TLS implementation". But if you want to write, say, a Mac application that feels like it was written in Swift, this is a weird wart that requires a lot of custom code to get around.
2. System administrator choices regarding the trust database (basically, "which certificate authorities do we trust") are not respected. This is very problematic in enterprise environments which typically want to install their own certificate authorities for their internal systems: unless they happen to be using Linux-with-OpenSSL on all their machines, this doesn't necessarily work nicely.
3. Users often don't realise they are trusting the OpenSSL that their Python is linked against: in many cases, they don't know where it came from! This is bad on systems that don't ship OpenSSL themselves (Windows) or that ship *ancient* OpenSSLs (macOS), as those libraries will often not be kept up-to-date with security fixes. This exposes users who use Python-based applications to risks they would not have encountered with native applications.

I need to emphasise here: the problem is not that Python cannot use alternative TLS stacks. Of course it can. The problem is that because the standard library provides a TLS implementation, there is a strong incentive to write to it. In general, the standard library of a language exerts a *strong* influence over the kinds of applications that get written, and given that for many of Python's historical uses the `ssl` module has been "good enough", there has been little impetus to support other models.

What we need to solve this problem is a kind of lubricant: something that makes it so easy to support non-OpenSSL TLS implementations that there is simply no reason not to do it. This will allow the Python community to move towards a model whereby libraries and tools can feel more like platform-native programs.

Longer-term, it will also reduce the reliance of Python on OpenSSL. The core Python development team should not be required to ship OpenSSL along with their code to support users on Windows and macOS. This isn't their job or their primary skill set, and it fundamentally puts the Python development team on the hook for providing security updates to OpenSSL's schedule. It should be possible to ship a version of Python to Windows and Mac users that does not require them to have OpenSSL on their system if they don't want to.

This is the first step in a long journey that will require a lot of work. I'd like not to be the only person pushing this boulder up this particular hill. Come help me out.


[^1]: There are plenty of low-level languages that aren't systems languages, and arguments can be made that some high-level languages are also systems languages (just ask any Go fan).

