---
layout: article
title: "Configuring TLS With Requests"
image:
  feature: palais.jpg
---

A common problem encountered by Requests users is that they need to perform some specific configuration of TLS. This can happen for a number of reasons, but the most common problem is that Requests has a default TLS configuration that is fairly strict. In particular, we recently removed support for all cipher suites that use the 3DES stream cipher. Unfortunately, for many older servers (particularly those that do not support TLSv1.1 or TLSv1.2), these were the last cipher suites we had in common with those servers.

Now, removing 3DES was in general the right thing to do. [Recent advances in cryptanalysis](https://sweet32.info/) mean that 3DES is insecure for bulk-transfer: a long-lived connection that transfers a large amount of data using 3DES can be attacked and can have encrypted data exfiltrated by a determined attacker. Of course, for many users this is not a plausible attack vector (for example, one-off scripts that do batch work), but we need to protect *all* our users, and the only way to ensure that users are not accidentally exposed to this attack is to remove it from our list altogether[^1].

Naturally, a number of users want to add this back. Historically this was a difficult thing to do in Requests, but in more recent versions (since v2.12.0) it has become possible to get extremely low-level configuration of Requests' TLS settings on a per-host level. This blog post will demonstrate how to do this to specifically re-add 3DES support for a single host, but in general this allows arbitrarily-detailed TLS configuration.

## How It Works

The feature added in Requests v2.12.0 is that urllib3 now accepts an `SSLContext` object in the constructors for `ConnectionPool` objects. This `SSLContext` will be used as the factory for the underlying TLS connection, and so all settings applied to it will also be applied to those low-level connections.

The best way to do this is to use the `SSLContext` factory function `requests.packages.urllib3.util.ssl_.create_urllib3_context`. This is analogous to Python's `ssl.create_default_context` function but applies the more-strict default TLS configuration that Requests and urllib3 both use. This function will return an `SSLContext` object that can then have further configuration applied. On top of that, the function also takes a few arguments to allow overriding default configuration.

To provide the new `SSLContext` object, you will need to write a [`TransportAdapter`](http://docs.python-requests.org/en/master/user/advanced/#transport-adapters) that is appropriate for the given host.

Below is an example of how to re-enable 3DES in Requests using this method.

    import requests
    from requests.adapters import HTTPAdapter
    from requests.packages.urllib3.util.ssl_ import create_urllib3_context

    # This is the 2.11 Requests cipher string, containing 3DES.
    CIPHERS = (
        'ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+HIGH:'
        'DH+HIGH:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+HIGH:RSA+3DES:!aNULL:'
        '!eNULL:!MD5'
    )


    class DESAdapter(HTTPAdapter):
        """
        A TransportAdapter that re-enables 3DES support in Requests.
        """
        def init_poolmanager(self, *args, **kwargs):
            context = create_urllib3_context(ciphers=CIPHERS)
            kwargs['ssl_context'] = context
            return super(DESAdapter, self).init_poolmanager(*args, **kwargs)

        def proxy_manager_for(self, *args, **kwargs):
            context = create_urllib3_context(ciphers=CIPHERS)
            kwargs['ssl_context'] = context
            return super(DESAdapter, self).proxy_manager_for(*args, **kwargs)

    s = requests.Session()
    s.mount('https://some-3des-only-host.com', DESAdapter())
    r = s.get('https://some-3des-only-host.com/some-path')

This is all you need to do! This works for essentially all TLS configuration you might want to do. Let us know if you have further problems with configuring TLS in Requests.

[^1]: Incidentally, those with eagle-eyes will note that this means that for anyone using a version of OpenSSL earlier than 1.1.0, Requests now *only* supports AES-based cipher suites. That is, for the vast majority of TLS users in the world there is only one symmetric cipher that is safe to be deployed in TLS. ChaCha20 does resolve this issue for those with newer OpenSSLs, but still, let's all hope AES stays resistant to attack!