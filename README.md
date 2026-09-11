*This project has been created as part of the 42 curriculum by mradouan*

# Inception

## Description

### What is Inception:

**Inception** is a system administration and Docker project from the 42 curriculum. The goal of this project is to build a small web infrastructure using **Docker**, where each service runs inside its own container.

The infrastructure is composed of several services working together:

- **NGINX** as the web server and entry point.
- **WordPress** with **PHP-FPM** to run the WordPress application.
- **MariaDB** as the database server.
- **Docker volumes** to persist website and database data.
- A **Docker network** to allow the containers to communicate with each other.

## Instructions

### Prerequisites

you need the following installed locally:

- docker
- docker compose
- make

### Compilation

```bash
make
```

### Test Inception

#### Website

Open your **browser** and navigate to:

```
https://mradouan.42.fr
```

#### Adminer

Open your **browser** and navigate to:

```
https://mradouan.42.fr/adminer
```

#### Portfolio

Open your **browser** and navigate to:

```
http://localhost:80
```

#### Portainer

Open your **browser** and navigate to:

```
http://localhost:9000
```

### Clean project 

```bash
make fclean
```

## Resources

### Documentation

- **docker docs:**  [Docker docs](https://docs.docker.com/get-started/docker-overview/)

- **TLS handshake** [TLS handshake](https://www.cloudflare.com/learning/ssl/transport-layer-security-tls/)


### Videos

- "Docker - Containers - Images - Volumes"

  https://youtu.be/Xnu-zoqopNM?si=gSESfGMZjouN_n3d

- "What is docker"

  https://youtu.be/8Zi_8-9f7xk?si=WQaGu3mFZX2lbwtQ

- "What is cash"

  https://youtu.be/IjGbxl-ubLs?si=9ljogYScoe7enemb

  https://youtu.be/YEk4CmmGVJ4?si=mlzjrekKzzJaMrzF

  https://youtu.be/Qxt-_cDz-A0?si=3fhE_JjrqyTA_X_n




### AI Usage

  The AI tools **ChatGPT** were used as learning and debugging tools throughout the project. and they used for :

  - Undestanding concepts related to docker, including docker archetecture, Networking, volumes, dockerCLI.

  - Get infos for creating scripts and understanding bash commands
  
  - Improve the project's **README** including its structure, wording and grammar and formatting.


## Project description

### Docker

Docker is used to package each service together with its required software and configuration into an **image**. Containers are then created from these images.

The project uses **Dockerfiles** to build the service images and **Docker Compose** to define, build, configure, network, and start the complete infrastructure.

This makes the infrastructure reproducible and avoids installing NGINX, PHP-FPM, WordPress, and MariaDB directly on the host system.

### Main Design Choices

The main design choices of the project are:

- **One service per container** to keep services isolated and follow the principle of separation of responsibilities.
- **NGINX as the only public entry point**, with HTTPS enabled.
- **PHP-FPM separated from NGINX** instead of installing PHP directly inside the NGINX container.
- **MariaDB separated from WordPress** so that the database has its own environment.
- **Docker named volumes** are used to persist the WordPress files and MariaDB database data even when containers are removed or recreated.
- A dedicated **Docker network** is used for communication between the services.
- Containers are configured to **restart automatically** if they stop unexpectedly.
- Configuration and sensitive values are managed through environment variables and the project's **`.env`** file.

### Sources

The project uses official and publicly available software and documentation as sources, including:

- **Debian** as the base Linux distribution for the containers.
- **NGINX** as the web server.
- **WordPress** as the CMS.
- **PHP / PHP-FPM** to execute WordPress PHP code.
- **MariaDB** as the relational database server.
- **Docker** and **Docker Compose** for containerization and orchestration.

The project also contains custom configuration files, Dockerfiles, initialization scripts, and configuration files written specifically to build and connect these services together.

## Virtual Machines vs Docker

Both **Virtual Machines (VMs)** and **Docker containers** are used to isolate applications and their environments, but they work differently.
```
| `Virtual Machines`                                    | `Docker Containers`                                                              | ____________________________________________________________________________________________________________________________________________
| Virtualizes an entire machine.                        | Virtualizes/isolate processes at the OS level.                                   |
| Each VM contains its own operating system and kernel. | Containers share the host machine's kernel.                                      |
| Requires a hypervisor such as VirtualBox or VMware.   | Uses the Docker Engine and Linux kernel features such as namespaces and cgroups. |
| Generally requires more CPU, RAM, and disk space.     | Generally uses fewer resources.                                                  |
| Takes longer to start because an entire OS must boot. | Starts quickly because there is no separate OS to boot.                          |
| Provides stronger isolation at the machine/OS level.  | Provides process-level isolation.                                                |
```
### Example

With a Virtual Machine :

```text
Host Machine
└── Hypervisor
    ├── VM 1
    │   └── Full Linux OS
    │       └── NGINX
    │
    ├── VM 2
    │   └── Full Linux OS
    │       └── WordPress
    │
    └── VM 3
        └── Full Linux OS
            └── MariaDB
```

With Docker :
```text
Host Machine
└── Linux Kernel
    └── Docker Engine
        ├── NGINX Container
        ├── WordPress + PHP-FPM Container
        └── MariaDB Container
```

## Secrets vs Environment Variables

Both **Secrets** and **Environment Variables** can be used to provide configuration values to containers, but they are not equally suitable for sensitive information.

```
| `Secrets`                                                                      | `Environment Variables`                                                                          |
_____________________________________________________________________________________________________________________________________________________________________________________
| Designed specifically for sensitive information.                               | Mainly designed for configuration values.                                                        |
| Suitable for passwords, API keys, certificates, and other confidential data.   | Suitable for values such as database names, usernames, ports, and configuration options.         |
| Can be managed separately from the application configuration.                  | Values are directly provided to the container environment.                                       |
| Provides better protection for sensitive information.                          | Sensitive values can be exposed through container inspection or process/environment information. |
| Usually mounted into the container as files or handled by a secrets mechanism. | Usually accessed by the application through environment variables.                               |
| Preferred for credentials and other secrets.                                   | Convenient for non-sensitive configuration.                                                      |
```
### Example

An environment variable can be used for normal configuration:

```yaml
environment:
  MYSQL_DATABASE: wordpress
  MYSQL_USER: wp_user
```

## Docker Network vs Host Network

Docker provides different networking modes for containers. Two important modes are **Docker Network** and **Host Network**.

```
| `Docker Network`                                                         | `Host Network`                                                       |
___________________________________________________________________________________________________________________________________________________
| The container gets its own network namespace.                          | The container shares the host's network namespace.                     |
| The container has its own IP address inside the Docker network.        | The container uses the host's IP address.                              |
| Containers can communicate with each other through the Docker network. | Containers communicate directly through the host's network stack.      |
| Provides better network isolation.                                     | Provides little network isolation from the host.                       |
| Ports can be explicitly published from the container to the host.      | Container ports are directly exposed on the host's network interfaces. |
| Docker manages the container's networking.                             | The host manages the container's networking.                           |
| Suitable for multi-container applications.                             | Useful when an application needs direct access to the host network.    |
```

## Docker Volumes vs Bind Mounts

Both **Docker Volumes** and **Bind Mounts** allow data to persist outside the container's writable layer, but they differ in how the data is managed and where it is stored.

| Docker Volumes                                                              | Bind Mounts                                                  |
______________________________________________________________________________________________________________________________________________
| Managed by Docker.                                                          | Managed directly by the user.                                |
| Docker decides where the data is stored on the host.                        | The user specifies the exact host path.                      |
| Created and managed using Docker commands.                                  | Directly connects a host directory or file to the container. |
| More portable and easier to manage with Docker.                             | More dependent on the host's filesystem structure.           |
| Provides a clear separation between the host filesystem and container data. | Gives the container direct access to a specific host path.   |
| Recommended for persistent application data.                                | Useful when the container needs direct access to host files. |

### Docker Volume

A Docker volume is created and managed by Docker:

```bash
docker volume create wordpress-data
```