# Dockerfile

## What is a Dockerfile?

A **Dockerfile** is a simple text document containing a sequential set of instructions used to automatically build a Docker image.

---

# The Core Instruction Set

We can categorize Dockerfile instructions into **three distinct phases**:

1. **Setup** → `FROM`
2. **Construction** → `COPY`, `RUN`
3. **Execution** → `CMD`, `ENTRYPOINT`

---

# 1. The Setup Phase — `FROM`

## `FROM`

`FROM` specifies the **base image** from which the Docker image is built.

It provides the initial filesystem and environment. The following Dockerfile instructions then add the application and its configuration on top of it.

Example:

```dockerfile
FROM debian:bookworm
```

This means:

```text
Debian Bookworm
      ↓
    FROM
      ↓
Our Docker image
```

---

# 2. The Construction Phase — `COPY`, `RUN`

## `COPY`

`COPY` is the preferred tool for copying files and directories from the **build context** into the Docker image.

It is mainly used to add files from our project into the image.

Example:

```dockerfile
COPY tools/script.sh /script.sh
```

This means:

```text
Project
  │
  └── tools/script.sh
          │
        COPY
          ↓
Docker image
  │
  └── /script.sh
```

---

## `RUN`

`RUN` executes a command **during the image build process**.

It is used to install packages, create directories, modify files, download software, compile programs, and perform other operations needed to construct the image.

Example:

```dockerfile
RUN apt-get update
RUN apt-get install -y nginx
```

The important point is:

> `RUN` happens when the **image is being built**, not when the container starts.

```text
Dockerfile
    ↓
docker build
    ↓
RUN commands
    ↓
Docker image
```

---

# 3. The Execution Phase — `CMD`, `ENTRYPOINT`

These instructions do **not** execute commands while the image is being built.

Instead, they write information into the image configuration that tells Docker what to execute when a container is started.

```text
Dockerfile
    ↓
docker build
    ↓
Image
    ↓
docker run / docker compose up
    ↓
CMD / ENTRYPOINT
    ↓
Application starts
```

---

## `CMD`

`CMD` defines the **default command** that runs when the container starts.

Example:

```dockerfile
CMD ["./script.sh"]
```

The default command can be replaced when starting the container.

---

## `ENTRYPOINT`

`ENTRYPOINT` defines the **main executable** of the container.

Example:

```dockerfile
ENTRYPOINT ["nginx"]
```

Unlike `CMD`, the `ENTRYPOINT` is not normally replaced when you provide a command to the container.

---

## `CMD` vs `ENTRYPOINT`

| | `CMD` | `ENTRYPOINT` |
|---|---|---|
| Purpose | Default command / arguments | Main executable |
| Can be overridden easily? | Yes | Not normally |
| Can work alone? | Yes | Yes |
| Can work together? | Yes | Yes |
| Common use | Default command or arguments | Fixed main program |

### Easy way to remember

```text
CMD        → What should run by default?
ENTRYPOINT → What is the main program?
```

They can also work together:

```dockerfile
ENTRYPOINT ["nginx"]
CMD ["-g", "daemon off;"]
```

Result:

```text
nginx -g "daemon off;"
```

So:

> `ENTRYPOINT` defines the main program, while `CMD` can provide its default arguments.