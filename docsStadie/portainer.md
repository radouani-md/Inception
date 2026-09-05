# Portainer

## What is Portainer?

Portainer is a **web-based graphical interface for managing Docker**.

Instead of managing Docker only with commands in the terminal, Portainer provides a web interface where we can manage Docker resources visually.

For example, we can manage:

- Containers
- Images
- Networks
- Volumes
- Container logs
- Container status

## Why do we use Portainer?

We use Portainer in the Inception project as an additional service to make managing and monitoring our Docker environment easier.

It allows us to:

- See all running containers from a web interface.
- Start, stop, and restart containers.
- View container logs.
- Manage Docker images, networks, and volumes.
- Monitor the state of our Docker environment.

Portainer communicates with the Docker Engine through the Docker socket:

```text
/var/run/docker.sock
```

The architecture is:

```text
Browser
   |
   | HTTP/HTTPS
   v
Portainer
   |
   | Docker API
   v
/var/run/docker.sock
   |
   v
Docker Engine
   |
   +-- NGINX
   +-- WordPress
   +-- MariaDB
   +-- Redis
```

### Simple definition for the defense

> **Portainer is a web-based interface used to manage and monitor Docker containers and other Docker resources. We use it in Inception to provide an easy graphical way to manage our Docker environment.**

### why wget and ca-certificate

We need `wget` because we're going to download Portainer from GitHub.

This `ca-certificates` installs trusted CA certificates into Debian.

Because we're connecting to: https://github.com

HTTPS uses certificates to verify the remote server.

So ca-certificates helps tools such as wget verify GitHub's TLS certificate.

Think of tar and gz as two different things.

1. What is tar?

tar is an archive format/tool.

Its job is to put multiple files and directories together into one file.

For example, imagine Portainer has:

portainer/
├── portainer
├── public/
├── templates/
└── ...

tar can pack all of these into:

portainer.tar

Important: tar itself does not compress the files. It mainly groups them together.

2. What is gz?

gz means gzip compression.

gzip takes a file and compresses it to make it smaller.

For example:

portainer.tar
     ↓ gzip
portainer.tar.gz

So:

.tar = archive

.gz = gzip compression

`portainer.tar.gz` it means: A tar archive that has been compressed with gzip

the `-z` tells tar:

"This archive is gzip-compressed, so decompress it first."

Then `tar` extracts the contents

`Decompress` = make something smaller → normal size
`Extract` = take files OUT of an archive

SO, 
   x = extract
   z = gzip
   f = file/archive to use

`-C` means change directory.

It tells tar:

"Before extracting the files, go to /opt/portainer."

Normally:

tar -xzf portainer.tar.gz -C /opt/portainer

would produce:

/opt/portainer/
└── portainer/
    ├── portainer
    ├── public/
    └── templates/

But with:

``--strip-components=1``

the first portainer/ is removed:

/opt/portainer/
├── portainer
├── public/
└── templates/

So:

`--strip-components=1`

basically means:

"Remove the first directory level from the paths while extracting."

## Docker compose volumes

`/var/run/docker.sock` from this volume he show us the status of each container ?

Yes — but not because the volume stores the status.

The volume:

- /var/run/docker.sock:/var/run/docker.sock

gives Portainer access to the Docker Engine API.

Portainer asks Docker Engine for information such as:

Is the container running?
What is its name?
What image is it using?
What ports does it expose?
What is its CPU/memory usage?
What are its logs?

### the Flow 

Portainer → Docker API → "Give me the containers"
                         ↓
                    Docker Engine
                         ↓
              WordPress: running
              MariaDB: running
              Nginx: stopped