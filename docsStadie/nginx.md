# NGINX

NGINX is the web server and reverse proxy used as the entry point to the infrastructure. It receives HTTPS requests from the client and forwards PHP requests to the WordPress/PHP-FPM container.

The general architecture is:

```text
Browser
   |
   | HTTPS :443
   v
NGINX
   |
   | FastCGI
   v
WordPress + PHP-FPM
   |
   +------> MariaDB
   |
   +------> Redis
```


## Dockerfile Explanation


Installs:

- `nginx` → the web server.
- `openssl` → tools used to create and manage TLS certificates and private keys.

The `-y` option automatically answers `yes` to the installation confirmation.

#### `rm -rf /var/lib/apt/lists/*`

Removes the downloaded package lists after installation.

These lists are no longer needed, so removing them reduces the image size.

---

### Create the SSL directory

```dockerfile
RUN mkdir -p /etc/nginx/ssl
```

Creates the directory where NGINX will store the TLS certificate and private key:

```text
/etc/nginx/ssl/
├── server.crt
└── server.key
```

---

### Copy the NGINX configuration

```dockerfile
COPY conf/nginx.conf /etc/nginx/nginx.conf
```

Copies the NGINX configuration from the project into the container.

The source file is:

```text
conf/nginx.conf
```

and the destination is:

```text
/etc/nginx/nginx.conf
```

This is the configuration NGINX uses when it starts.

---

### Copy the TLS certificate

```dockerfile
COPY --chmod=644 certs/server.crt /etc/nginx/ssl/server.crt
```

Copies the certificate into the container.

The `644` permissions mean:

```text
rw-r--r--
```

The owner can read and write the file, while the group and other users can read it.

The certificate is not secret, so it can be readable.

---

### Copy the private key

```dockerfile
COPY --chmod=600 certs/server.key /etc/nginx/ssl/server.key
```

Copies the private TLS key into the container.

The `600` permissions mean:

```text
rw-------
```

Only the owner can read or modify the file.

The private key must be protected because it is secret cryptographic information.

Therefore:

```text
server.crt → public certificate → 644
server.key → private key        → 600
```

---

### Start NGINX

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

Starts NGINX when the container starts.

#### `nginx`

Starts the NGINX server.

#### `-g`

Allows a global NGINX configuration directive to be specified from the command line.

#### `daemon off;`

Normally NGINX runs as a daemon and moves into the background.

In Docker, we want NGINX to remain in the foreground so that it stays as the main process of the container.

```text
Docker container
       |
       v
   NGINX
       |
       └── foreground
```

This allows Docker to monitor and manage the NGINX process correctly.

---

# TLS Certificates

Because the project requires HTTPS, NGINX needs:

1. A **TLS certificate**.
2. A **private key**.

They are used together to establish a secure HTTPS connection.

```text
Browser
   |
   | HTTPS
   v
NGINX
   |
   +-- server.crt  → certificate
   |
   +-- server.key  → private key
```

## Creating a self-signed certificate

For a development project such as Inception, we can create a self-signed certificate using OpenSSL.

First, create a directory for the certificates:

```bash
mkdir -p certs
```

Then generate the private key and certificate:

```bash
openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout certs/server.key \
    -out certs/server.crt
```

### Explanation

#### `openssl`

Runs OpenSSL.

#### `req`

Works with certificate requests and certificates.

#### `-x509`

Creates a self-signed X.509 certificate instead of creating a certificate signing request that will later be signed by a Certificate Authority.

#### `-nodes`

Means that the private key is not encrypted with a password.

This is useful for a Docker container because NGINX needs to start automatically without waiting for someone to enter a password.

#### `-days 365`

Makes the certificate valid for 365 days.

#### `-newkey rsa:2048`

Creates a new RSA private key with a 2048-bit key size.

#### `-keyout certs/server.key`

Specifies where the generated private key will be saved:

```text
certs/server.key
```

#### `-out certs/server.crt`

Specifies where the generated certificate will be saved:

```text
certs/server.crt
```

After running the command, we have:

```text
nginx/
├── Dockerfile
├── conf/
│   └── nginx.conf
└── certs/
    ├── server.crt
    └── server.key
```

## Why do we need both files?

The private key and certificate have different roles.

### `server.key`

The private key is secret and is used by NGINX during the TLS process.

It should not be shared publicly.

```text
server.key
     |
     └── PRIVATE
```

### `server.crt`

The certificate contains the public information used to identify the server and establish the TLS connection.

```text
server.crt
     |
     └── PUBLIC
```

The certificate can be shared with clients; the private key must remain protected.

## Certificate flow

When the browser connects to the website:

```text
Browser
   |
   | HTTPS connection
   v
NGINX
   |
   | Uses server.crt
   | Uses server.key
   v
TLS handshake
   |
   v
Encrypted HTTPS connection
```

NGINX then handles the HTTPS connection and forwards the appropriate requests to the WordPress/PHP-FPM container.

## Important note about self-signed certificates

A self-signed certificate is suitable for a local development environment such as this project.

Because it is not signed by a trusted public Certificate Authority, a browser will normally display a certificate/security warning.

This does **not** mean that TLS encryption is not being used. It means that the browser cannot establish trust in the certificate's issuer.

For a real public website, you would normally use a certificate issued by a trusted Certificate Authority.