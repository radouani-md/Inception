# Adminer

## What is Adminer?

What is Adminer?

Adminer is a web-based database management tool.

It gives you a graphical interface in your browser to work with databases such as MariaDB, MySQL, PostgreSQL, etc.

## Why do we use Portainer?

Instead of doing everything from the terminal:

mysql -u root -p

you can open Adminer in your browser and manage your database through a web interface.

For example, Adminer lets you:

Connect to MariaDB
Create databases and tables
View and edit data
Run SQL queries
Create users
Import/export databases

`PHP-FPM `is the PHP interpreter/process manager that executes Adminer's PHP code.

Adminer is a PHP application, and Adminer needs PHP to run and a PHP `database extension` to communicate with MariaDB.

### Simple definition for the defense

> **Adminer is a web-based tool that allows us to manage and interact with our MariaDB database through a web browser instead of using the command line.**


#### Now the important part: -L
-L

means:

--location

It tells curl:

Follow HTTP redirects.

This is important because the URL you request doesn't necessarily directly return the final file.

What is an HTTP redirect?

Imagine you request:
```
https://www.adminer.org/latest.php
```
The server could respond:

```
HTTP/1.1 302 Found
Location: https://somewhere.example/adminer-5.x.x.php
```
The server is basically saying:

"The resource you requested is over there. Go to this other URL."

This is called a **redirect**.

The important HTTP header is:

Location:

For example:
```
HTTP/1.1 301 Moved Permanently
Location: https://example.com/new-location
```
or:
```
HTTP/1.1 302 Found
Location: https://example.com/temporary-location
```

```
curl
  │
  │ GET /latest.php
  ▼
Adminer server
  │
  │ 302
  │ Location: /adminer.php
  ▼
curl
  │
  │ GET /adminer.php
  ▼
Server
  │
  │ 200 OK
  │ PHP content
  ▼
curl
```
### Defense answer
> **curl downloads the Adminer PHP application. -L tells curl to follow HTTP redirects, so if latest.php redirects to another URL, curl follows the redirect and downloads the final resource. -o saves the downloaded file as /var/www/html/index.php.**