# TLS Handshake

## What is the TLS handshake?

The **TLS handshake** is the process that happens before encrypted communication starts.

Its main goals are:

1. Agree on the TLS version and cryptographic algorithms.
2. Verify the server's identity using its certificate.
3. Establish a shared secret key.
4. Use that key to encrypt the actual HTTP communication.

The basic idea is:

```text
Browser                         NGINX
   |                              |
   | -------- Hello ------------> |
   |                              |
   | <------- Certificate ------- |
   |                              |
   | ---- Key exchange ---------->|
   |                              |
   | <---- Key exchange ----------|
   |                              |
   | ===== Encrypted HTTPS =====> |
```

---

# 1. Client Hello

The browser starts by sending a **ClientHello** to NGINX.

It basically says:

> "Hello NGINX. I want to establish a TLS connection. Here are the TLS versions and cryptographic algorithms I support."

For example:

```text
ClientHello

TLS versions:
    TLS 1.3
    TLS 1.2

Supported cipher suites:
    ...

Random value:
    ...
```

The browser also sends information needed for the key exchange.

---

# 2. Server Hello

NGINX responds with **ServerHello**.

It chooses the parameters that will be used.

For example:

```text
ServerHello

TLS version:
    TLS 1.3

Cipher suite:
    TLS_AES_256_GCM_SHA384
```

Now both sides know which TLS version and cryptographic parameters they will use.

---

# 3. NGINX sends its certificate

NGINX sends its certificate to the browser.

For your Inception project, this is the certificate you created:

```text
/etc/nginx/ssl/server.crt
```

The certificate contains information such as:

```text
Domain name
Public key
Certificate validity
Issuer
Signature
...
```

The browser receives the certificate and checks whether it can trust it.

---

# 4. Certificate verification

If the certificate was issued by a trusted **Certificate Authority (CA)**, the browser checks the certificate chain.

The idea is:

```text
Certificate
     |
     v
Who signed it?
     |
     v
Trusted CA?
     |
   +---+
   |   |
  Yes  No
   |   |
   v   v
Trusted  Warning
```

In your Inception project, you are using a **self-signed certificate**.

That means the certificate is signed by itself rather than by a trusted CA.

Therefore, the browser may display a warning such as:

```text
Your connection is not private
```

This does **not** mean that TLS encryption is not working.

It means the browser cannot verify the certificate using a trusted CA.

---

# 5. Key exchange

Now the browser and NGINX need to establish a **shared secret**.

The important point is that they do not simply send the secret key directly over the network.

Conceptually:

```text
Browser                    NGINX
   |                         |
   |   Key exchange data     |
   | ----------------------> |
   |                         |
   | <---------------------- |
   |   Key exchange data     |
   |                         |
   v                         v

        Same shared secret
```

Modern TLS commonly uses **(EC)DHE** for key exchange.

Both sides use the exchanged information to independently calculate the same shared secret.

This secret is then used to derive the symmetric encryption keys.

---

# 6. Finished messages

Both sides verify that the handshake was completed correctly.

They exchange **Finished** messages.

Conceptually:

```text
Browser
   |
   | Finished
   v
NGINX
   |
   | Finished
   v
Browser
```

If everything is correct, the TLS handshake is complete.

---

# 7. Encrypted HTTP starts

Now the TLS connection is established.

The browser can send the actual HTTP request:

```http
GET / HTTP/1.1
Host: example.com
```

But the HTTP data is encrypted while travelling through the network:

```text
Browser
   |
   | 🔒 Encrypted HTTP
   v
NGINX
```

NGINX decrypts the request and processes it.

---

# Complete TLS handshake

For your Inception architecture:

```text
                  TLS HANDSHAKE

Browser                                      NGINX
   |                                           |
   | ----------- ClientHello ----------------> |
   |                                           |
   | <---------- ServerHello ----------------- |
   |                                           |
   | <---------- server.crt ------------------ |
   |                                           |
   | ----------- Key Exchange ---------------->|
   |                                           |
   | <---------- Key Exchange -----------------|
   |                                           |
   | <---------- Finished -------------------->|
   |                                           |
   |                                           |
   |        TLS connection established         |
   |                                           |
   | ======== Encrypted HTTP request ========> |
   |                                           |
   | <========= Encrypted HTTP response ====== |
```

---

# What you need to remember for the defense

Remember these **3 main things**:

### 1. Certificate

```text
server.crt
```

The certificate identifies the server and contains its public key.

### 2. Key exchange

The browser and NGINX establish a shared secret without directly sending that secret over the network.

### 3. Symmetric encryption

After the handshake, the actual HTTP data is encrypted using symmetric encryption keys because symmetric encryption is much faster for transferring data.

---

## Simple definition

> **The TLS handshake is the negotiation process between the client and server that establishes the TLS version, authenticates the server using its certificate, and creates shared encryption keys before encrypted HTTP communication begins.**