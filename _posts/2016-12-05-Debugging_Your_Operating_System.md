---
layout: article
title: "Debugging Your Operating System: A Lesson In Memory Allocation"
comments: true
image:
  feature: palais.jpg
  teaser: palais-teaser.jpg
---

*Edit: Hello Hacker News! Good to see you again! I don't want to take away the fun of reading my post digging into memory management, and the joy you'll have in finding every little mistake I have made. But I feel obliged to remind you all that while it's great to focus on technical esoterica (I get it, it's really fun!), we don't write our software in a vacuum. So in addition to seeking out technical content that educates and edifies, which I hope my own does, I also strongly encourage you to seek out writing that educates and challenges you on political topics. As software developers we are uniquely privileged to be at the forefront of revolutionising society over the next few decades, and it is incumbent upon us to be as informed and nuanced as we can be about the role our work plays in society as a whole.*

*To that end, I encourage you to challenge the [Hacker News decision to censor what it calls "political" content](https://news.ycombinator.com/item?id=13108404). While I understand that moderating this content is difficult, I believe that we need to [accept the discomfort that comes from confronting the possible harm that we do to the world, in order to ensure that we leave the world better than we found it](https://www.africa.upenn.edu/Articles_Gen/Letter_Birmingham.html). For my part, I encourage you all to consider whether you have an ethical obligation to be involved with building the best world you can, and whether doing that involves actively engaging with those who disagree with you. Please also consider supporting publications that produce long-form work that provides alternative and valuable viewpoints: if you need a starting point, consider [Model View Culture](https://modelviewculture.com/) or your local best source of investigative journalism. I also strongly recommend that you consider whether [the risk of the rise of fascism](https://www.theguardian.com/artanddesign/jonathanjonesblog/2016/dec/09/war-memorials-have-failed-peter-eisenman-holocaust) in Europe and the United States requires action on your part to ensure that your employer and community do not contribute to a repeat of the horrors of the mid twentieth century.*

*With that light-hearted reminder out of the way, we now return to our regularly scheduled content. Enjoy the post!*

It began, as so many investigations do, with [a bug report](https://github.com/kennethreitz/requests/issues/3729).

The name of the bug report was simple enough: "iter_content slow with large chunk size on HTTPS connection". This is the kind of name of a bug report that immediately fires alarm bells in my head, for two reasons. Firstly, it's remarkably difficult to quantify: what does "slow" mean here? How slow? How large is large? Secondly, it's the kind of thing where it seems like if the effect was severe we'd have heard about it by now. We've had the `iter_content` method for a very long time: surely if it were meaningfully slower in a reasonably common use mode we'd have heard about it by now.

Quickly leaping into the initial report, the original reporter provides relatively little detail, but does say this: "This causes 100% CPU and slows down throughput to less than 1MB/s.". That catches my eye, because it seems like it cannot possibly be true. The idea that merely downloading data with minimal processing could be that slow: surely not!

However, all bugs deserve investigation before they can be ruled out. With some further back-and-forth between myself and the original poster, we got ourselves to a reproduction scenario: if you used Requests with PyOpenSSL and ran the following code, you'd pin a CPU to 100% and find your data throughput had dropped down to extremely minimal amounts:

    import requests
    https = requests.get("https://az792536.vo.msecnd.net/vms/VMBuild_20161102/VirtualBox/MSEdge/MSEdge.Win10_preview.VirtualBox.zip", stream=True)
    for content in https.iter_content(100 * 2 ** 20): # 100MB
        pass

This is a *great* repro scenario, because it points the finger so clearly into the Requests stack. There is *no* user-supplied code running here: all of the code is shipped as part of the Requests library or one of its dependencies, so there is no risk that the user wrote some wacky low-performance code. This is really fantastic. Even more fantastic, this is a repro scenario that uses a public URL, which means *I can run it*! And when I did, I reproduced the bug. Every time.

There was one other bit of tantalising detail:

> At `10MB`, there is no noticeable increase in CPU load, and no impact on throughput. At `1GB`, CPU load is at `100%`, just like with `100MB`, but throughput is reduced to below `100KB/s`, compared to `1MB/s` at `100MB`.

This is a really interesting data point, because it implies the *literal value* of the chunk size is affecting the work load. When we combine this information with the fact that this only occurs in PyOpenSSL, and the fact that the stack spends most of its time in the following line of code, the problem becomes clear:

    File "/home/user/.local/lib/python2.7/site-packages/OpenSSL/SSL.py", line 1299, in recv
      buf = _ffi.new("char[]", bufsiz)

Some further investigation determined that CFFI's default behaviour for `FFI.new` is to return *zeroed* memory. This meant that there was linear overhead in the allocation size: for bigger allocations we had to spend more time zeroing data. Hence the bad behaviour with large allocations. We used a CFFI feature to disable the zeroing of memory for these buffers, and the problem went away[^1]. Problem solved, right?

Wrong.

## The Real Bug

All joking aside, this genuinely did resolve the problem. However, a few days later, Nathaniel Smith asked a very insightful question: [why was the memory being actively zeroed at all](https://bitbucket.org/cffi/cffi/issues/295/cffinew-is-way-slower-than-it-should-be-it)? To understand this question, we need to digress a bit into memory allocation in POSIX systems.

### mallocs and callocs and vm_allocs, oh my!

Many programmers are familiar with the standard way to ask your operating system for memory. That mechanism is through using the C standard library function `malloc` (you can read documentation about it on your system by typing `man 3 malloc` for the manual page). This function takes a single argument, a number of bytes to allocate memory for. The C standard library will use one of many different strategies for allocating this memory, but one way or another it will return a pointer to a bit of memory that is *at least as large* as the amount of memory you asked for.

By the standard, `malloc` returns *uninitialized memory*. This means that the C standard library locates some memory and immediately passes it to your program, without changing what is *already there*. This means that in standard use `malloc` can and will return a buffer to your program that your program has already written data into. This behaviour is a common source of nasty bugs in languages that are memory-unsafe, like C, and in general reading from uninitialized memory is an extremely dangerous pattern.

However, `malloc` has a friend, documented right alongside it in the same manual page: `calloc`. Now, `calloc`'s most obvious difference from `malloc` is that it takes *two* arguments: a count, and a size. That is, when you all `malloc` you ask the C standard library "please allocate at least *n* bytes", whereas when you call `calloc` you ask the C standard library "please allocate enough memory for *n* objects of size *m* bytes". It is clear that the *original intent* of `calloc` is to allocate heap memory for arrays of objects in a safe way[^2].

But `calloc` has an extra side effect, related to its original purpose to allocate arrays, and mentioned very quietly in the manual page:

> The allocated memory is filled with bytes of value zero.

This goes hand-in-hand with `calloc`'s original purpose. If you were, for example, allocating an array of values, it is often very helpful for your array to *begin* in a default state. Some modern, memory-safe languages have actually adopted this as the default behaviour when building arrays and structures. For example, in the Go programming language, when you initialize a structure all of its members are defaulted to their so-called "zero" values, which are basically equivalent to "what their value would be if everything were set to zero". This can be thought of as a promise that all Go structures are allocated using `calloc`[^3].

This behaviour means that while `malloc` returns uninitialized memory, `calloc` returns *initialized* memory. And because it does so, and has these strict promises, the operating system can optimise it. And indeed, most modern operating systems *have* optimised it.

### Let's go calloc

Of course, the simplest way to implement `calloc` is to write it like this:

    void *calloc(size_t count, size_t size) {
        assert(!multiplication_would_overflow(count, size));

        size_t allocation_size = count * size;
        void *allocation = malloc(allocation_size);
        memset(allocation, 0, allocation_size);
        return allocation;
    }

The cost of a function like this is clearly approximately linear in the size of the allocation: setting each byte to zero is clearly going to become increasingly expensive as you have more bytes. Now, in fact, most operating systems ship C standard libraries that have *optimised* paths for `memset` (usually by taking advantage of specialised CPU vector instructions to zero a lot of bytes in each instruction), but nevertheless the cost of doing this is linear.

But operating systems have another trick up their sleeve for larger allocations, and that's to take advantage of virtual memory tricks.

### Virtual Memory

Fully explaining virtual memory is going beyond the scope of this blog post, unfortunately, but I highly recommend you read up about it (it's very interesting stuff!). However, the short version of "virtual memory" is that the operating system kernel will lie to processes about memory. Each process running on your machine has its own view of memory which belongs to it and it alone. That view of memory is then "mapped" onto physical memory indirectly.

This allows the operating system to perform all kinds of clever trickery. One very common form of clever trickery is to have some bits of "memory" that are actually files. This is used when swapping memory out to disk, and is also used when memory-mapping a file. In the case of memory mapping a file, a program will ask the operating system: "please allocate *n* bytes of memory and back those bits of memory with this file on disk, such that when I write to the memory those writes are written to the file on disk, and when I read from that memory those reads come from the file on disk".

The way this works, at a kernel level, is that when the process tries to read that memory the CPU will notice that the memory the process is reading does not actually exist, will pause that process, and will emit a "page fault". The operating system kernel will be invoked and will act to *bring* the data into memory so that the application can read it. The original process will then be unpaused and find, from its perspective, that no time has passed and that magically the bytes of the file are present in that memory location.

This mechanism can be used to perform other neat tricks. One of them is to make very large memory allocations "free"; or, more properly, to make them expensive only in proportion to how much of that memory is *used*, rather than in proportion to how much of that memory is *allocated*.

The reason for doing this is that historically many programs that needed a decent chunk of memory during their lifetime would, at startup, allocate a *massive* buffer of bytes that it could then parcel out internally over the program's lifetime. This was done because the programs were written for environments that do not use virtual memory, and so they needed to call dibs on a certain amount of memory to avoid getting starved out. But with virtual memory, such a policy is no longer needed: each program can allocate as much memory as it needs on-demand, they can no longer starve each other out[^4].

So, to help avoid these applications from having very large startup costs, operating systems started to lie to them about large allocations. On most operating systems, if you attempt to allocate more than about 128 kilobytes in one call, the C standard library will ask the operating system directly for brand-new virtual memory pages that cover that many bytes. But, and this is key, *this costs almost nothing to do*. The operating system doesn't actually allocate or commit any memory at this point: it just sets up some virtual memory mappings. This makes this operation *extremely cheap* at the time of the `malloc` call.

Of course, because that memory hasn't been "mapped in" to the process, the moment the application tries to *actually use* that memory a page fault will occur. At this point, the operating system will find an actual page of memory and put it in place, much like the page fault for a memory-mapped file (except the virtual memory will be backed by physical memory, instead of by a file).

The net result of this is that on most modern operating systems, if you call `malloc(1024 * 1024 * 1024)` to allocate one gigabyte of memory, that will happen almost immediately because actually, nothing has been done to truly give your process that memory. As a result, a program that allocates many gigabytes of memory that it never actually uses will execute quite quickly, so long as those allocations are quite large.

What is potentially more surprising is that the same optimisation can be made for `calloc`. This works because the operating system can map a brand new page to the so-called "zero page": a page of memory that is read-only, and reads entirely as zeroes. This mapping is initially copy-on-write, which means that when your process eventually tries to write to its brand new memory map the kernel will intervene, copy all those zeroes into a new page, and then apply your write.

Because the OS can do this trick `calloc` can, for larger allocations, simply do the same as `malloc` does, and ask for brand-new virtual memory pages. This continues to have no cost until the memory is actually used. This neat optimisation means that `calloc(1024 * 1024 * 1024, 1)` costs exactly the same as `malloc` of the same size does, despite `calloc`'s additional promise of zeroing memory. Neat!

### Back To The Bug

So, as Nathaniel pointed out: if CFFI was using `calloc`, why would the memory be being zeroed out?

Part one, of course, is that it doesn't always use `calloc`. But I had a suspicion that I'd bumped into a case where I could reproduce this slowdown directly with `calloc`, so I went back and coded up a quick repro program. I came up with this:

    #include <stdlib.h>

    #define ALLOCATION_SIZE (100 * 1024 * 1024)

    int main (int argc, char *argv[]) {
        for (int i = 0; i < 10000; i++) {
            void *temp = calloc(ALLOCATION_SIZE, 1);
            free(temp);
        }
        return 0;
    }

This is a very simple C program that allocates and frees 100MB of memory using `calloc` ten thousand times, and then exits. There are two likely possibilities for what might happen here[^5]:

1. `calloc` may use the virtual memory trick described above. In this case, we'd expect this program to be very fast indeed: because the memory that we allocate never actually gets used, it never gets paged in and so the pages never get dirtied. The OS does its little trick of lying to us about allocating memory, and we never call the OS's bluff, so everything works out beautifully.
2. `calloc` may use `malloc` and zero memory manually using `memset`. We'd expect this to be very, very slow: in total we need to zero one *terabyte* of memory (ten thousand increments of 100 MB), and that takes quite a lot of effort.

Now, this is well above the standard OS threshold for using behaviour (1), so we'd expect that behaviour. And indeed, on Linux, that's exactly what you see: if you compile this with `gcc` and then run it you'll find that it executes very quickly indeed, and causes very few page faults, and exerts very little memory pressure. But if you take the same program and run it on macOS, you'll find it takes an *extremely* long time: in my testing it took nearly *eight minutes*.

Even more weirdly, if you make `ALLOCATION_SIZE` bigger (say `1000 * 1024 * 1024`) then suddenly the macOS program becomes almost instantaneous! *What the hell?*

What is happening here?

### Go Source Diving

macOS contains a neat utility called `sample` (see `man 1 sample`) that can tell you quite a lot about a running process by sampling its process state. The `sample` output for the program above looked like this:

    Sampling process 57844 for 10 seconds with 1 millisecond of run time between samples
    Sampling completed, processing symbols...
    Sample analysis of process 57844 written to file /tmp/a.out_2016-12-05_153352_8Lp9.sample.txt

    Analysis of sampling a.out (pid 57844) every 1 millisecond
    Process:         a.out [57844]
    Path:            /Users/cory/tmp/a.out
    Load Address:    0x10a279000
    Identifier:      a.out
    Version:         0
    Code Type:       X86-64
    Parent Process:  zsh [1021]

    Date/Time:       2016-12-05 15:33:52.123 +0000
    Launch Time:     2016-12-05 15:33:42.352 +0000
    OS Version:      Mac OS X 10.12.2 (16C53a)
    Report Version:  7
    Analysis Tool:   /usr/bin/sample
    ----

    Call graph:
        3668 Thread_7796221   DispatchQueue_1: com.apple.main-thread  (serial)
          3668 start  (in libdyld.dylib) + 1  [0x7fffca829255]
            3444 main  (in a.out) + 61  [0x10a279f5d]
            + 3444 calloc  (in libsystem_malloc.dylib) + 30  [0x7fffca9addd7]
            +   3444 malloc_zone_calloc  (in libsystem_malloc.dylib) + 87  [0x7fffca9ad496]
            +     3444 szone_malloc_should_clear  (in libsystem_malloc.dylib) + 365  [0x7fffca9ab4a7]
            +       3227 large_malloc  (in libsystem_malloc.dylib) + 989  [0x7fffca9afe47]
            +       ! 3227 _platform_bzero$VARIANT$Haswel  (in libsystem_platform.dylib) + 41  [0x7fffcaa3abc9]
            +       217 large_malloc  (in libsystem_malloc.dylib) + 961  [0x7fffca9afe2b]
            +         217 madvise  (in libsystem_kernel.dylib) + 10  [0x7fffca958f32]
            221 main  (in a.out) + 74  [0x10a279f6a]
            + 217 free_large  (in libsystem_malloc.dylib) + 538  [0x7fffca9b0481]
            + ! 217 madvise  (in libsystem_kernel.dylib) + 10  [0x7fffca958f32]
            + 4 free_large  (in libsystem_malloc.dylib) + 119  [0x7fffca9b02de]
            +   4 madvise  (in libsystem_kernel.dylib) + 10  [0x7fffca958f32]
            3 main  (in a.out) + 61  [0x10a279f5d]

    Total number in stack (recursive counted multiple, when >=5):

    Sort by top of stack, same collapsed (when >= 5):
            _platform_bzero$VARIANT$Haswell  (in libsystem_platform.dylib)        3227
            madvise  (in libsystem_kernel.dylib)        438

The key note here is that we can clearly see that we're spending the bulk of our time in `_platform_bzero$VARIANT$Haswell`. This method is used to zero buffers. This means that macOS is zeroing out the buffers. Why?

Well, handily, Apple open-sources much of their core operating system code sometime after release. We can see that this program spends most of its time in `libsystem_malloc`, so I simply went to [Apple's Open Source webpage](https://opensource.apple.com/), and downloaded a tarball of [libmalloc-116](https://opensource.apple.com/source/libmalloc/libmalloc-116/), which contains the relevant source code. And then I went spelunking.

It turns out that all of the magic happens in [`large_malloc`](https://opensource.apple.com/source/libmalloc/libmalloc-116/src/magazine_large.c.auto.html). This branch is used for allocations larger than about 127kB, and ultimately does use the virtual memory trick above. So why do we have really slow execution?

Well, here is where it turns out that Apple got a bit too clever for their own good. `large_malloc` contains a whole bunch of code hidden behind a `#define` constant, `CONFIG_LARGE_CACHE`. This whole bunch of code basically amounts to a "free-list" of large memory pages that have been allocated to the program. If a macOS program allocates a contiguous buffer of memory between 127kB and `LARGE_CACHE_SIZE_ENTRY_LIMIT` (approximately 125MB), then `libsystem_malloc` will attempt to re-use those pages if another allocation is made that could use them. This saves it from needing to ask the Darwin kernel for some memory pages, which saves a context switch and a syscall: a non-trivial savings, in principle.

However, for `calloc` it is naturally the case that we need those bytes to be zeroed. For that reason, if macOS finds a page that can be reused and has been called from `calloc`, it will *zero the memory*. All of it. Every time.

Now, this isn't totally unreasonable: zeroed pages are legitimately a limited resource, especially on resource constrained hardware (looking at you, Apple Watch). That means that if it is possible to re-use a page, that's potentially a really major savings.

*However*, the page cache totally destroys the optimisation of using `calloc` to provide zeroed memory pages. That wouldn't be so bad if it was only done to "dirty" pages: that is, if the pages that it was zeroing out had been written to by the application, and so were likely to not be zeroed. But macOS does this *unconditionally*. That means, if you call `calloc`, `free`, and `calloc`, without ever touching the memory, the second call to `calloc` takes the pages allocated by the first one, which were never backed by actual memory, and *forces* the OS to page in all that memory in order to zero it, even though *it was already zeroed*. This is part of what we were trying to avoid with the virtual-memory based allocator for large allocations: this memory, which was not ever used, *becomes* used by the free-list.

The net effect of this is that on macOS `calloc` has a cost that is linear in allocation size all the way up to 125MB, despite the fact that most other operating systems get O(1) behaviour after about 127kB. Over 125 MB macOS stops caching the pages, and so all of a sudden everything gets speedy and great again.

This is a really unexpected bug to find from a Python program, and it raises a number of questions. For example, how many CPU cycles are wasted zeroing memory that was already zeroed. How many context switches are wasted by forcing applications to page-in memory they never used and didn't need so that the OS could unnecessarily zero it?

Ultimately, though, I think this shows the truth of the old adage: [all abstractions are leaky](http://www.joelonsoftware.com/articles/LeakyAbstractions.html). Just because you're a Python programmer doesn't mean you're able to forget that, somewhere down in the depths, you are running on a machine that is built up of memory, and trickery. Someday, your program is going to be *really* unexpectedly slow, and the only way to find out is to dive all the way down into your operating system to work out what silly thing it is doing to your memory.

This bug has been filed as [Radar 29508271](rdar://29508271). It is hands-down one of the weirdest bugs I've ever encountered.

**Edit 1**: A previous version of this post talked about operating system kernels zeroing pages in idle time. That's not really the way it works in modern OSes: instead, a copy-on-write version of a zero-page is used. This is another neat optimisation that allows kernels to avoid spending lots of time writing zeroes into used pages: instead, they only write the zeroes when an application actually writes data into its pages. This has the effect of saving even more CPU cycles: if an application asks for memory that it literally never touches, then it never costs anything to fill it with zeroes. Neat!


[^1]: A quick side note: many of you may ask why this is safe to do. Of course, CFFI is not just zeroing buffers for the hell of it: generally speaking it is much better to use initialized memory than to use uninitialized memory, particularly when interacting with raw memory directly from a managed language, so zeroing this data is substantially safer than not doing so. However, in this case the `char` array we're building is being immediately passed into OpenSSL so that it can write data into the buffer, and we are telling OpenSSL *how long the buffer is*. This means that OpenSSL is immediately writing over our freshly-zeroed bytes up to the maximum length of the buffer. When we get the buffer back, OpenSSL tells us how many bytes it wrote, so we just copy that many bytes out of the buffer and throw it away. This means that each byte in the buffer is either a) written with a zero by us, then written by OpenSSL, then copied out by us, or b) written with a zero by us and never looked at again. In either case, the first step (us writing zeroes into the buffer) is unnecessary: either OpenSSL will overwrite the zero, so we didn't need it, or we'll never look at the byte again so it doesn't matter what value it has. As a general principle, buffers used in this way do not need to be zeroed.

[^2]: When I say "in a safe way", I feel compelled to clarify. An enormous amount of C code that wants to allocate heap memory for arrays will make a call like this: `type *array = malloc(number_of_elements * size_of_element)`. This is a dangerous pattern, because it is possible that the multiplication here will *overflow*: that is, `number_of_elements` multiplied by `size_of_element` may be too large to fit into a certain number of bits, and so the program may quietly ask for *too little data*. `calloc` protects against this by including overflow-checking code when it does the multiplication of the element count and the element size, and if that calculation overflows it will return an appropriate error.

[^3]: I should stress that I said "can be thought of", not "is guaranteed to be". I have not investigated the Go runtime to check this.

[^4]: Of course, they *can* starve each other of *physical* memory, but that's a separate problem.

[^5]: All of this assumes that you don't compile with optimisations on: the optimiser can trivially optimise this entire program away!
