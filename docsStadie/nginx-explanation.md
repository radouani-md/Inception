This Nginx configuration is the HTTPS entry point of your Inception project. Its main job is:

Client → Nginx (HTTPS :443) → PHP-FPM in WordPress/Adminer containers

Let's go line by line.

1. server { ... }
server {

A server block defines one virtual server in Nginx.

It tells Nginx:

"When a request matches these conditions, handle it using these rules."

2. listen 443 ssl;
listen 443 ssl;

This tells Nginx to:

listen on port 443
use SSL/TLS

Port 443 is the standard port for HTTPS.

So when you access:

https://mradouan.42.fr

the browser connects to:

Nginx:443

The important point is that TLS is terminated by Nginx.

The browser establishes the encrypted TLS connection with Nginx.

3. server_name
server_name mradouan.42.fr;

This specifies the domain name handled by this server block.

So Nginx expects requests like:

https://mradouan.42.fr

The browser sends something similar to:

GET / HTTP/1.1
Host: mradouan.42.fr

Nginx uses the Host header to determine which server block should handle the request.

4. Document root
root /var/www/html;

This defines the root directory for files.

For example, if Nginx receives:

https://mradouan.42.fr/index.html

it looks for:

/var/www/html/index.html

And for:

https://mradouan.42.fr/test.php

the corresponding filesystem path is:

/var/www/html/test.php

However, PHP files are handled by the PHP location below rather than served directly.

5. index
index index.php index.html;

This tells Nginx which files to look for when the URL points to a directory.

For example:

https://mradouan.42.fr/

Nginx checks:

/var/www/html/index.php

first.

If it doesn't find it, it checks:

/var/www/html/index.html

For WordPress, index.php is normally the important one.

6. SSL certificate
ssl_certificate /etc/nginx/ssl/server.crt;

This tells Nginx where its TLS certificate is located.

The certificate is presented to the browser during the TLS handshake.

The browser uses it to verify the identity of the server and establish encrypted communication.

7. SSL private key
ssl_certificate_key /etc/nginx/ssl/server.key;

This is the private key corresponding to the certificate.

The private key must be kept secret.

Together:

server.crt
     +
server.key
     ↓
TLS/HTTPS
8. TLS versions
ssl_protocols TLSv1.2 TLSv1.3;

This specifies which TLS versions Nginx accepts.

Only:

TLS 1.2
TLS 1.3

are allowed.

Older protocols such as TLS 1.0 and TLS 1.1 are disabled.

This is also an important part of the 42 Inception requirement.

9. PHP location
location ~ \.php$ {

This is very important.

The:

~

means Nginx uses a regular expression for matching.

The expression:

\.php$

means:

Match URLs ending in .php.

For example:

/index.php       → MATCH
/wp-login.php    → MATCH
/wp-admin/test.php → MATCH
/image.jpg       → NO MATCH

So PHP requests enter this block.

10. include fastcgi_params
include fastcgi_params;

This includes standard FastCGI parameters that Nginx sends to the PHP-FPM server.

These parameters contain information about the request, such as:

REQUEST_METHOD
QUERY_STRING
CONTENT_TYPE
SERVER_NAME
SERVER_PROTOCOL

etc.

Nginx needs these because PHP-FPM needs information about the HTTP request in order to execute the PHP script correctly.

11. fastcgi_pass
fastcgi_pass wordpress:9000;

This is one of the most important lines.

It tells Nginx:

"Send this PHP request to the container called wordpress, on port 9000."

Your Docker network provides DNS resolution.

So:

wordpress

is the Docker container/service name.

And:

9000

is the port where PHP-FPM is listening.

The architecture is therefore:

Browser
   |
   | HTTPS :443
   ↓
 Nginx
   |
   | FastCGI :9000
   ↓
wordpress container
   |
   ↓
 PHP-FPM
   |
   ↓
WordPress PHP
Important

Nginx is not executing PHP.

Nginx receives the request and forwards the PHP request to PHP-FPM.

PHP-FPM executes the PHP code and returns the result to Nginx.

12. SCRIPT_FILENAME
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

This tells PHP-FPM:

"Which PHP file should you execute?"

There are two variables here.

$document_root

Because you defined:

root /var/www/html;

we have:

$document_root = /var/www/html
$fastcgi_script_name

This represents the requested PHP path.

For:

https://mradouan.42.fr/index.php

we have:

$fastcgi_script_name = /index.php

Nginx combines them:

$document_root$fastcgi_script_name

becomes:

/var/www/html/index.php

So Nginx tells PHP-FPM:

Execute:
/var/www/html/index.php
13. Your comment

You wrote:

#$document_root=/var/www/html , $fastcgi_script_name=/index.php  URL=https://localhost/index.php

Exactly.

For example:

URL:
https://mradouan.42.fr/index.php

        ↓

$document_root
/var/www/html

        +

$fastcgi_script_name
/index.php

        ↓

SCRIPT_FILENAME
/var/www/html/index.php
14. Adminer location

Now this part is different:

location = /adminer {

The = means exact match.

So this location matches exactly:

/adminer

For example:

https://mradouan.42.fr/adminer

It does not generally match:

/adminer/test
/adminer.php
/adminer/

because this is an exact-match location.

15. FastCGI parameters for Adminer
include fastcgi_params;

Same idea as before.

Nginx prepares the request information that PHP-FPM needs.

16. Send Adminer request to Adminer container
fastcgi_pass adminer:9000;

This is different from WordPress:

fastcgi_pass wordpress:9000;

Here Nginx sends the request to:

adminer

on:

9000

So:

Browser
   |
   | HTTPS
   ↓
 Nginx
   |
   | FastCGI
   ↓
adminer container
   |
   ↓
PHP-FPM
   |
   ↓
Adminer PHP application
17. Adminer SCRIPT_FILENAME
fastcgi_param SCRIPT_FILENAME /var/www/html/index.php;

This explicitly tells PHP-FPM:

Execute:
/var/www/html/index.php

Unlike the WordPress location, you're not constructing the filename from variables.

You're saying directly:

"When /adminer is requested, execute /var/www/html/index.php inside the Adminer container."

This is useful because Adminer is distributed as essentially a single PHP application file, commonly named index.php.

The complete flow

When you open:

https://mradouan.42.fr

the flow is approximately:

                 HTTPS :443
Browser ─────────────────────────→ Nginx
                                      |
                                      | PHP request
                                      | FastCGI :9000
                                      ↓
                                wordpress:9000
                                      |
                                      ↓
                                   PHP-FPM
                                      |
                                      ↓
                                  WordPress

For Adminer:

Browser
   |
   | HTTPS :443
   ↓
 Nginx
   |
   | /adminer
   |
   | FastCGI :9000
   ↓
adminer:9000
   |
   ↓
 PHP-FPM
   |
   ↓
Adminer /var/www/html/index.php
Simple defense definition

Nginx is the HTTPS reverse proxy and web server. It listens on port 443, handles TLS, serves static files, and forwards PHP requests to the appropriate PHP-FPM container using FastCGI. WordPress requests go to wordpress:9000, while /adminer requests go to adminer:9000.