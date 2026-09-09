# Namespaces and Cgroups

## What they need you to understand

### A container is not a kernel object
There is no `struct container` or `create_container()` in Linux.
A container is basically a normal Linux process with an isolated environment.

### Why isolation is needed
Normally, processes on Linux share the same system resources.
Without isolation, applications could conflict over:
- ports
- files
- processes
- network
- libraries

### chroot was an early form of isolation
chroot changes what a process sees as `/`.
But it only isolates the filesystem.
It does not properly isolate network, processes, IPC, etc.

### Namespaces + cgroups are the important technologies

Namespaces = what a process can SEE
cgroups = what a process can USE

For example:

Namespace → container sees its own processes.
cgroup → container can be limited to 512 MB RAM.

### Docker uses Linux kernel features
Docker doesn't create a miniature virtual machine.
It asks the Linux kernel to create an isolated process.
System calls such as `clone()` are involved in creating isolated processes.

### Why containers are lightweight
Containers share the host's Linux kernel.
They don't need a complete guest OS like a VM.
That's why you can run many containers efficiently on one machine.

### Brief version for your defense

A container is not a virtual machine or a special object inside the Linux kernel. It is a normal Linux process running in an isolated environment. Linux provides this isolation mainly through namespaces and cgroups. Namespaces control what the process can see, while cgroups control how much resources it can use. Docker uses these Linux kernel features to isolate applications while allowing them to share the host kernel, making containers much lighter than virtual machines.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

This section is mainly trying to make you understand what Namespaces are, why Docker uses them, and how they create isolation for processes.

## What they need you to understand

### What is a Namespace?
A Namespace is a Linux kernel mechanism for isolation.
It makes a group of processes see only a limited view of system resources.
The processes behave as if they have their own resources.

### Without Namespaces
Normally, Linux has global resources shared by all processes.
For example:
- All processes see the same process IDs.
- They see the same network interfaces.
- They see the same mount points.
- They can use the same IPC resources.

### What Namespaces do
Namespaces create an isolated view of these resources.

For example, a process inside a container might see:

```
PID 1
PID 2
PID 3
```

while the host sees many more processes.

The processes inside don't know about the host's other processes.

### There is no "container" inside the kernel
The kernel doesn't have a special container object.
Instead, each process has information pointing to the namespaces it belongs to.
The text mentions nsproxy, which is part of the process's kernel-side data and links it to its namespaces.

### How the kernel knows what to show
When a process asks the kernel for something, the kernel checks which namespace the process belongs to.

For example:

```
Process → asks "show me network interfaces"
               ↓
Kernel → checks process's network namespace
               ↓
Kernel → returns only interfaces visible there
```

### clone()
Docker needs to create an isolated process.
It can use the Linux clone() system call.
clone() is similar to fork(), but more powerful for this purpose.
It allows Docker to specify which namespaces the new process should be isolated into.

### fork() vs clone()

Think of it simply like this:

**fork()**

"Create another process in basically the same environment."

**clone()**

"Create another process and let me control which parts of its environment are isolated."

For containers, clone() can be used with namespace flags such as:

```
CLONE_NEWPID   → new PID namespace
CLONE_NEWNET   → new network namespace
CLONE_NEWNS    → new mount namespace
CLONE_NEWUTS   → new hostname/UTS namespace
```

### Brief version for your defense

Namespaces are Linux kernel features used to isolate processes. They give processes a separate view of system resources such as PIDs, networks, mount points, and IPC. A container uses these isolated views so that processes inside the container cannot normally see the corresponding resources of other containers or the host. Docker can create isolated processes using the clone() system call and specify which namespaces they should use.

### Key sentence to memorize

Namespaces control what a process can see.

And remember the difference from the previous section:

```
Namespaces = visibility
cgroups = resource limits
```

---

This section is mainly trying to make you understand how Docker isolates networking for each container and how containers still communicate with the outside world.

## What they need you to understand

### What is a Network Namespace?

A Network Namespace creates a separate networking environment for a process.
It has its own:
- network interfaces
- IP addresses
- routing tables
- firewall rules
- sockets and ports

The flag used to create it is:

```
CLONE_NEWNET
```

### What does a new NET namespace initially contain?

When a new network namespace is created, it doesn't have the host's network interfaces.

It initially has only:

```
lo
```

lo = loopback interface.

It allows a process to communicate with itself using addresses such as 127.0.0.1.

### The container cannot directly see the host network

A process inside the container cannot simply access the host's physical network interface such as:

```
eth0
```

It has its own isolated network stack.

### How does the container get network access?

Docker uses a veth pair.

Think of a veth pair as a virtual network cable with two ends:

```
HOST                         CONTAINER
─────────                    ─────────
docker0 bridge
    │
    │ veth
    └───────────────┐
                    │
                 eth0
                    │
               Container
```

One end is in the host namespace.

The other end is inside the container's network namespace and is usually called eth0.

### Why can multiple containers use port 80?

Because each container has its own network namespace.

For example:

```
Container A → 192.168.1.10:80
Container B → 192.168.1.11:80
```

Both can listen on port 80 because they are in different network environments.

Important: this is not the same as saying two processes can always bind the exact same host IP and port. The isolation comes from the separate network namespaces.

### What happens to ss or tcpdump?

If you run:

```
ss -tuln
```

inside a container, you see the sockets belonging to that container's network namespace, not all the host's sockets.

Similarly, network inspection tools operate within the namespace they are running in.

### How does Docker connect containers together?

Docker combines several things:

```
Network namespaces
       ↓
   veth pairs
       ↓
   Docker bridge
       ↓
  routing / firewall
       ↓
   Network access
```

This is how containers can communicate with:
- other containers
- the host
- the Internet

### Simple example

Suppose you have two containers:

WordPress container
IP: 172.18.0.2
Port: 9000

MariaDB container
IP: 172.18.0.3
Port: 3306

They have separate network namespaces, but Docker connects them through its virtual network.

So WordPress can communicate with:

```
mariadb:3306
```

without MariaDB needing to expose port 3306 to the host.

That's an important concept for your Inception project.

### Brief version for your defense

A Network Namespace isolates the networking stack of a container. It gives the container its own network interfaces, IP addresses, routing tables, firewall rules, and sockets. Docker uses a virtual Ethernet pair, or veth pair, to connect the container's network namespace to a Docker bridge on the host. Because each container has its own network namespace, different containers can use the same port internally without conflicting.

### Key things to memorize

- NET Namespace = isolated network environment
- CLONE_NEWNET = creates a network namespace
- veth pair = virtual cable connecting namespaces
- eth0 = container's network interface
- docker0 = Docker's bridge on the host

And the easiest sentence to remember:

The NET namespace gives each container its own network stack.

## 3. MNT Namespace

The Mount (MNT) Namespace, created via CLONE_NEWNS, was the first namespace added to the Linux kernel. It provides a clear form of isolation by giving a process a completely independent view of the filesystem. Unlike the old chroot command, which only changed the root folder, the Mount Namespace separates the entire list of mounts from the main system. A process inside this namespace can mount or unmount filesystems such as mounting a temporary disk at /tmp or linking a host folder to /app without these changes affecting the host machine or other containers. This allows every container to have its own private /proc, /sys, and /dev directories, which are needed for tools inside the container to work properly without seeing information about the host hardware or other running processes.

When a container starts, the Docker engine uses the pivot_root system call a more secure and thorough alternative to chroot to swap the entire root filesystem of the process with the container image's root filesystem. This operation physically detaches the process from the host's root mount, ensuring that even if the process breaks out of its jail, it has no file descriptors linking it back to the host's underlying storage.

This section is mainly trying to make you understand how the Mount Namespace isolates the filesystem seen by a container, and why it is more powerful than chroot.

### What they need you to understand

#### What is a Mount Namespace?

A Mount Namespace gives a process its own view of the filesystem mounts.
The flag used to create it is:

```
CLONE_NEWNS
```

So two processes can have different mount configurations even though they use the same Linux kernel.

#### chroot vs Mount Namespace

chroot basically says:

"For this process, consider this directory to be /."

But Mount Namespace goes further:

"Give this process its own complete list of mounted filesystems."

For example, inside a container you can mount something at:

```
/tmp
```

without that mount automatically appearing in another mount namespace.

#### Why containers need this

A container needs its own filesystem view.

For example:

```
Host
├── /etc
├── /home
├── /var
└── ...

Container
├── /etc
├── /var
├── /usr
└── ...
```

The / that the container sees is based on the container's filesystem, not the normal host filesystem tree.

#### What about /proc, /sys, and /dev?

These are special filesystems used by Linux.

Containers can have their own appropriate views of them:

```
/proc → process information
/sys  → kernel/device information
/dev  → devices
```

This prevents normal container processes from simply seeing everything on the host.

#### What is pivot_root?

When starting a container, the root filesystem needs to be changed from the host's filesystem to the container's filesystem.

pivot_root can be used to switch the process to a different root filesystem.

Conceptually:

Before:

```
Process
   ↓
Host /
   ↓
/etc
/var
/home
...
```

After:

```
Process
   ↓
Container /
   ↓
/etc
/var
/usr
...
```

So when the application accesses:

```
/etc/nginx/nginx.conf
```

it is accessing the file from the container's root filesystem.

#### Important correction about the text

The text makes pivot_root sound like something Docker universally uses directly for every container startup. The important concept for your defense is changing the process's root filesystem inside an isolated mount environment. Modern container runtimes may use different mechanisms depending on the runtime and setup.

Also, Mount Namespace does not by itself make the container filesystem magically exist. The container runtime prepares the filesystem and mount configuration, then gives the container process that isolated view.

#### Simple example

Imagine the host has:

```
/home/user/project
```

and the container has:

```
/app
```

Inside the container, /app can be backed by a particular filesystem or mount without changing what another mount namespace sees.

That's why each container can have its own filesystem environment.

### Brief version for your defense

A Mount Namespace isolates the filesystem mount view of a process. It allows a container to have its own root filesystem and its own /proc, /sys, and /dev views. The CLONE_NEWNS flag is used to create a new Mount Namespace. Unlike chroot, which mainly changes the apparent root directory, a Mount Namespace provides an independent set of filesystem mounts. Container runtimes then switch the process to the container's root filesystem.

### Key things to memorize

- MNT Namespace = isolated filesystem/mount view
- CLONE_NEWNS = creates a Mount Namespace
- chroot = changes apparent root
- Mount Namespace = isolates the mount table
- pivot_root = switches the process to the container's root filesystem

And the easiest sentence:

The Mount Namespace controls which filesystems and mounts a process can see.

## 3. UTS, IPC, and USER Namespaces

The remaining namespaces finish the work of isolation. The UTS Namespace handles system identity, specifically allowing each container to have its own unique hostname separate from the host, which is important for logging and identifying services on a network. The IPC Namespace prevents containers from using shared memory to talk to each other; without this, a container could potentially read private data from the host or another application. Finally, the USER Namespace is a critical security layer that maps user IDs inside the container to different IDs on the host. This allows a process to run as the powerful "root" user inside the container while actually being a restricted, standard user on the host system, ensuring that even if an attacker manages to escape the container, they arrive on the host with no special permissions to do harm

This section is mainly trying to make you understand the three remaining namespaces and how they complete container isolation: identity, communication, and user privileges.

### What they need you to understand

#### 1. UTS Namespace — Identity

UTS stands for UNIX Timesharing System.

It allows a container to have its own hostname, different from the host.

For example:

```
Host:
hostname → my-computer

Container:
hostname → wordpress
```

Inside the container:

```
hostname
```

could return:

```
wordpress
```

while the host still has:

```
my-computer
```

So:

UTS Namespace = isolates the hostname/system identity.

#### 2. IPC Namespace — Communication

IPC means Inter-Process Communication.

Linux provides mechanisms such as:
- shared memory
- message queues
- semaphores

These allow processes to communicate.

The IPC Namespace isolates these resources.

For example:

```
Container A
    ↓
Shared memory A

Container B
    ↓
Shared memory B
```

Container A normally cannot simply access Container B's IPC resources.

So:

IPC Namespace = isolates inter-process communication resources.

#### 3. USER Namespace — User privileges

This one is very important for security.

A USER Namespace allows Linux to map user IDs between the container and the host.

For example:

```
Inside container          Host
─────────────────         ─────────────
UID 0 (root)       →      UID 100000
```

So a process can appear as:

```
root
```

inside the container, while on the host it is actually represented by an unprivileged UID.

This is called UID mapping.

#### Why is this useful?

Imagine a process runs as:

```
root
```

inside a container.

Without user namespace isolation, container root can potentially have significant privileges on the host if another vulnerability is exploited.

With user namespaces:

```
Container root
      ↓
UID mapping
      ↓
Unprivileged host user
```

So even if the process escapes the container, it doesn't automatically become host root.

Important: User namespaces are an additional security layer; they don't guarantee that a container escape is harmless. Container security also depends on capabilities, seccomp, LSMs, filesystem permissions, etc.

#### Simple way to remember all three

| Namespace | What it isolates |
|---|---|
| UTS | Hostname / system identity |
| IPC | Inter-process communication |
| USER | User IDs and privileges |

Think:

```
UTS  → "Who am I?"
IPC  → "Who can I communicate with?"
USER → "What permissions do I have?"
```

### Brief version for your defense

UTS, IPC, and USER namespaces provide additional isolation. UTS gives each container its own hostname. IPC isolates inter-process communication resources such as shared memory and message queues. USER namespaces isolate user IDs by mapping container UIDs to different host UIDs, allowing a process to be root inside the container while being an unprivileged user on the host.

### Key things to memorize

- UTS → hostname
- IPC → communication resources
- USER → users and privileges

And the easiest sentence:

UTS isolates identity, IPC isolates communication, and USER isolates privileges.

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

This section is mainly trying to make you understand what cgroups are, why Docker needs them, and how they control CPU and memory usage.

## What they need you to understand

### Why do we need cgroups?

Namespaces provide isolation, but they don't limit resources.

For example, a container may think:

"I am the only process on this system."

But physically it is still using the host's:
- CPU
- RAM
- Disk I/O

Without limits, one container could consume all the RAM or CPU and affect the entire host.

So:

```
Namespaces = isolation
cgroups = resource control
```

### What is a cgroup?

A Control Group (cgroup) is a Linux kernel mechanism that groups processes and controls/account for the resources they use.

For example:

```
Host
├── Container A
│    ├── nginx
│    └── php-fpm
│
└── Container B
     └── MariaDB
```

Docker can put the processes of Container A into one cgroup and Container B into another.

Then the kernel can apply different limits to each group.

### Where are cgroups represented?

You normally see them through:

```
/sys/fs/cgroup
```

This is a special virtual filesystem provided by the kernel.

You can inspect it with:

```
ls /sys/fs/cgroup
```

Docker/runtime creates cgroup structures and associates container processes with them.

### How does the kernel enforce the limits?

Imagine you configure:

```
Container → maximum 512 MB RAM
```

The container's processes use memory:

```
Process
   ↓
Kernel
   ↓
cgroup memory controller
   ↓
Is usage within the limit?
   ↓
Yes → allow
No  → memory pressure/OOM handling
```

The important point is:

Docker doesn't personally sit there checking the RAM every second. The Linux kernel enforces the cgroup limits.

### Memory Controller

The memory controller controls how much memory a cgroup can use.

For example:

```
docker run --memory=512m nginx
```

Conceptually:

```
Container
   │
   ├── nginx
   └── other processes
          ↓
       cgroup
          ↓
     512 MB limit
```

If the processes inside the cgroup cannot stay within the configured memory constraints, the kernel's OOM mechanism may kill processes to recover memory.

### Why do you sometimes see exit code 137?

137 commonly means:

```
128 + 9 = 137
```

where 9 is:

```
SIGKILL
```

So if a container exits with 137, one common reason is that a process was killed with SIGKILL, often because of an out-of-memory condition.

Don't memorize "137 always means OOM." It means the process was killed by SIGKILL; OOM is a common cause in containers.

### CPU Controller

Cgroups can also control CPU usage.

There are two important concepts in your text:

#### CPU shares / weights

This is about relative priority when CPUs are busy.

Example:

```
Container A → 1024 weight
Container B → 512 weight
```

If both are heavily using CPU and competing for CPU time:

```
A → approximately twice the CPU time
B → approximately half of A
```

The important word is relative.

It doesn't mean:

```
A = maximum 1024 CPU
```

It means:

When there is CPU contention, A gets more CPU time than B.

#### CPU quota / limit

This is a hard limit.

For example:

```
docker run --cpus=0.5 nginx
```

means roughly:

The container is allowed to consume the equivalent of half a CPU over the scheduler's accounting periods.

If the container tries to consume more than its allowed CPU time, the kernel throttles it.

So:

```
CPU demand
    ↓
cgroup CPU limit
    ↓
Allowed → execute
Too much → throttled
```

This can cause an application to become slower even though the host itself isn't using 100% CPU.

### cgroup v1 vs v2

You don't need to go extremely deep here for your defense. Understand the main difference.

#### cgroup v1

The controllers could have separate hierarchies.

Conceptually:

```
Memory hierarchy
    └── Group A

CPU hierarchy
    └── Group B
```

This made resource management more complicated.

#### cgroup v2

Uses a unified hierarchy.

Conceptually:

```
Unified cgroup
      │
      ├── memory
      ├── cpu
      └── io
```

So resource controllers are managed within a more consistent hierarchy.

Modern Linux systems commonly use cgroup v2.

### The most important distinction

You should be able to explain this without thinking:

```
             CONTAINER
                 │
        ┌────────┴────────┐
        ↓                 ↓
   NAMESPACES           CGROUPS
        │                 │
        ↓                 ↓
   What can I see?   How much can I use?
```

Example:

Namespace:
"Container can see only its own processes."

cgroup:
"Container can use at most 512 MB RAM."

### Brief version for your defense

Cgroups are Linux kernel mechanisms used to control and account for the resources consumed by groups of processes. Namespaces isolate what a container can see, while cgroups limit how much CPU, memory, and I/O it can use. Docker creates cgroups for containers and the Linux kernel enforces the limits. For example, a container can be limited to 512 MB of RAM or 0.5 CPU. If it exceeds its memory limit, the kernel may invoke the OOM mechanism, which can result in a process being killed with SIGKILL and the container commonly exiting with code 137.

### Key things to memorize

- cgroup = resource control
- /sys/fs/cgroup = cgroup virtual filesystem
- Memory limit → controls RAM
- CPU quota → hard CPU limit
- CPU weight/share → relative CPU priority during contention
- OOM → may kill processes when memory cannot be satisfied
- 137 → 128 + SIGKILL(9)
- cgroup v2 → unified hierarchy

And the easiest sentence:

Namespaces decide what the container can see; cgroups decide how much of the host's resources it can consume.

#### Conclusion

We have now successfully deconstructed the concept of a "container."

Through the analysis of Linux Kernel primitives, we established that a container is not a physical object, but a standard Linux process subjected to strict isolation.

Namespaces build the walls, limiting the process's visibility of the system.

Control Groups act as utility meters, preventing resource exhaustion.

Capabilities fracture the root privilege, ensuring security even for privileged users.

Union File Systems provide the efficient, layered storage that makes rapid deployment possible.

Together, these technologies create the convincing illusion of a standalone operating system. However, the kernel only provides the raw building blocks. Manually configuring these for every application would be unmanageable. We need a system to orchestrate this assembly.

Next Chapter: 03. The Docker Engine Architecture We will now move from kernel space to user space. We will examine the software stack that automates this complexity, tracing the specific roles of the components that power the ecosystem: dockerd, containerd, and runc.

# The Docker Engine Architecture

This section is mainly trying to make you understand the different components behind Docker and how they work together when you run a container.

The most important thing is: Docker is not one single program doing everything. Modern Docker uses several components, each with a specific job.

![image](docsStadie/images/aarcheDocker.avif)

## What they need you to understand

### 1. The Kernel provides the building blocks

From the previous sections, Linux gives us:

```
Namespaces   → isolation
cgroups      → resource limits
Capabilities → permissions
```

But Linux doesn't give you a command like:

```
create_container()
```

So something has to organize all these pieces.

That's what the Docker Engine does.

### 2. Docker vs dockerd vs containerd vs runc

This is the part you should really understand for your defense.

Think of the architecture like this:

```
You
 │
 │ docker run nginx
 ↓
Docker CLI
 │
 ↓
dockerd
 │
 ↓
containerd
 │
 ↓
runc
 │
 ↓
Linux Kernel
 │
 ├── Namespaces
 ├── cgroups
 └── capabilities
```

Each layer has a different responsibility.

### 3. Docker CLI — docker

When you type:

```
docker run nginx
```

the docker command is the Docker client / CLI.

It doesn't directly create the container by itself.

It sends your request to the Docker daemon:

```
docker CLI
    │
    │ API request
    ↓
dockerd
```

So:

docker = the command-line client you interact with.

### 4. Docker Daemon — dockerd

dockerd is the main Docker daemon.

It listens for requests from the Docker CLI and manages high-level Docker operations such as:
- images
- containers
- networks
- volumes
- Docker API

For example:

```
docker run nginx
```

The CLI essentially tells dockerd:

"I want an nginx container."

Then dockerd coordinates the work needed to create it.

So:

dockerd = the main Docker management daemon.

### 5. containerd

dockerd doesn't need to directly handle every low-level container operation.

It delegates container lifecycle management to containerd.

containerd is responsible for things such as:
- creating containers
- starting containers
- stopping containers
- managing container processes
- managing container lifecycle

Conceptually:

```
dockerd
   │
   │ "Create/start this container"
   ↓
containerd
```

So:

containerd = manages the container lifecycle.

### 6. runc

Now we go even lower.

containerd needs something that can actually create the container's isolated process using Linux kernel features.

That's where runc comes in.

runc is a low-level OCI runtime.

It interacts with Linux to create things such as:
- Namespaces
- cgroups
- process
- root filesystem

So:

```
containerd
    ↓
  runc
    ↓
Linux Kernel
```

runc essentially tells the kernel:

"Create this process with these namespaces, these resource limits, this root filesystem, etc."

So:

runc = low-level tool that creates/runs the container process using Linux kernel features.

### 7. What is OCI?

OCI stands for:

Open Container Initiative

It defines standards for containers.

The important idea is that Docker doesn't need to invent its own completely private container format.

OCI defines standards such as:
- Container Image Specification
- Container Runtime Specification

This allows different container tools to work with common standards.

For example:

```
Docker
   ↓
OCI-compatible runtime
   ↓
Linux
```

runc is an implementation of the OCI runtime specification.

### 8. Follow docker run nginx

This is probably the most useful thing to understand.

When you type:

```
docker run nginx
```

conceptually:

**Step 1 — Docker CLI**

```
docker
```

sends the request to dockerd.

**Step 2 — dockerd**

```
dockerd
```

handles the high-level Docker operation.

It determines what is needed, including the image and container configuration.

**Step 3 — containerd**

dockerd delegates container lifecycle work to:

```
containerd
```

**Step 4 — runc**

containerd uses an OCI runtime such as:

```
runc
```

to actually create/start the container process.

**Step 5 — Linux kernel**

runc asks the Linux kernel to create the isolated environment:

```
Namespaces
cgroups
capabilities
filesystem
process
```

And now you have a running container.

### Very important distinction

Don't say:

"dockerd creates the container directly."

A better explanation is:

The Docker CLI communicates with dockerd; dockerd manages the high-level Docker operations and delegates container lifecycle management to containerd; containerd uses an OCI runtime such as runc to create and run the container process using Linux kernel primitives.

### Brief version for your defense

The Docker Engine is a collection of components rather than one single program. The docker CLI is the client that sends commands to dockerd. dockerd is the main Docker daemon responsible for high-level management such as images, containers, networks, and volumes. It delegates container lifecycle management to containerd. containerd uses an OCI-compatible runtime such as runc, which interacts with the Linux kernel to create the actual isolated process using namespaces, cgroups, capabilities, and the container filesystem.

### Key things to memorize

```
docker     → Client / CLI
dockerd    → Docker management daemon
containerd → Container lifecycle
runc       → Low-level container runtime
OCI        → Container standards
Kernel     → Actually provides isolation/resources
```

### The easiest way to remember it

docker asks → dockerd manages → containerd supervises → runc creates → kernel isolates.

## The Client-Server Model

The most common misconception about Docker is that the docker command you type in your terminal is the tool that actually runs the containers. It is not. The docker binary is merely a lightweight client, a remote control that sends instructions to a completely separate background process. This architecture is known as the Client-Server model, and it is the fundamental design choice that allows Docker to run on operating systems like Windows and macOS, even though containers are a native Linux technology.

The Docker architecture is strictly divided into two primary actors:

**The Client (docker CLI):** This is the user interface. When you run commands like docker build, docker pull, or docker run, this binary does absolutely no heavy lifting. It parses your command, validates the flags, and converts your intent into a REST API request. It then transmits this request to the server and waits for the output to stream back to your terminal.

**The Server (The Daemon - dockerd):** This is the heavy lifter. It is a long-running background process (daemon) that listens for API requests. It manages the state of all Docker objects: images, containers, networks, and volumes. When the client says "run an nginx container," the daemon is the component that actually downloads the layers, configures the network, and instructs the kernel to start the proces.

### The Communication Channels

The bridge between the Client and the Server is the Docker API. Because the system is designed this way, the client and server do not need to be on the same machine. You can run the docker client on your laptop to manage a dockerd daemon running on a cloud server in another continent.

This communication happens over two possible channels (sockets):

### 1. The Unix Socket (/var/run/docker.sock)

This is the default and most secure method for local communication on Linux. A Unix Socket is a special type of file that allows two processes on the same operating system to exchange data efficiently without the overhead of the network stack.

**How it works:** When you install Docker on Linux, the daemon creates this socket file. By default, only the root user and members of the docker group have permission to read/write to this file.

**Security Implication:** This is why you typically need sudo to run docker commands. Adding your user to the docker group is effectively granting them password-less root access, because anyone who can write to this socket can instruct the daemon to launch a privileged container and take over the host.

### 2. The TCP Socket (HTTP/HTTPS)

This channel allows the client and server to communicate over a network.

**Use Case:** Managing remote servers. You can configure dockerd on a server to listen on port 2375 (unencrypted) or 2376 (encrypted TLS).

**The Risk:** Exposing the Docker daemon over plain TCP is one of the most common security vulnerabilities in the cloud. If port 2375 is open to the internet, anyone can connect their client to your server and launch a container to mine cryptocurrency or steal data. Production environments must always use Mutual TLS (mTLS) to authenticate the client.

![infos](docsStadie/images/internalarhetecture.avif)

This section goes one level deeper than 3.1. The previous section explained client ↔ daemon. This one explains what happens after dockerd receives your command.

The main thing they want you to understand is the chain of responsibility:

```
docker
   ↓
dockerd
   ↓
containerd
   ↓
runc
   ↓
Linux Kernel
```

Each component has a different job.

## 3.2 The Internal Architecture

Imagine you execute:

```
docker run -d nginx
```

It looks like one simple command to you, but internally it triggers several steps.

```
You
 │
 │ docker run -d nginx
 ↓
docker CLI
 │
 │ API request
 ↓
dockerd
 │
 │ prepare everything
 ↓
containerd
 │
 │ manage container lifecycle
 ↓
runc
 │
 │ create the actual container process
 ↓
Linux Kernel
 │
 ├── namespaces
 ├── cgroups
 ├── capabilities
 └── filesystem
```

Let's understand each one.

### 1. The Client: docker

The docker command is the client.

When you type:

```
docker run -d nginx
```

the CLI does things like:
- read your command
- understand -d
- understand nginx
- validate the command
- create an API request
- send that request to dockerd

For example, conceptually:

```
docker run -d nginx
        ↓
"Please create and start an nginx container"
        ↓
Docker API
        ↓
dockerd
```

The important thing:

The Docker CLI does NOT create the container itself.

It's basically a remote control.

That's why you can have:

```
Laptop
 └── docker CLI
        │
        │ network
        ↓
Server
 └── dockerd
```

Your Docker CLI doesn't need to be on the same machine as the daemon.

### 2. The Daemon: dockerd

Now the request arrives at:

```
dockerd
```

This is the Docker daemon.

dockerd is the high-level manager of Docker.

It handles things like:
- Images
- Containers
- Networks
- Volumes
- Docker API

Suppose you say:

```
docker run nginx
```

dockerd has to prepare the environment.

Conceptually:

```
dockerd
  │
  ├── Is nginx image available?
  │
  ├── If not → get the image
  │
  ├── Prepare filesystem
  │
  ├── Configure networking
  │
  ├── Prepare volumes
  │
  └── Ask containerd to start container
```

**Important**

dockerd doesn't directly create the Linux process using clone() itself.

It delegates the container lifecycle work further down the stack.

### 3. The Supervisor: containerd

Now we arrive at:

```
containerd
```

Think of containerd as the container lifecycle manager.

It takes responsibility for the container from:

```
create
  ↓
start
  ↓
running
  ↓
stop
  ↓
delete
```

It also handles important image-related work, such as:

```
Download image
      ↓
Store image
      ↓
Unpack image
```

So there is a distinction:

**dockerd**

High-level Docker management.

**containerd**

Container lifecycle and lower-level container management.

You can think of it as:

dockerd
"Hey containerd, I want this container running."

containerd
"Okay, I'll manage its lifecycle."

### 4. Why is containerd separate from Docker?

This is an important architectural idea.

Originally, Docker had much more functionality concentrated inside the Docker daemon.

Over time, container functionality was separated into independent components.

That's useful because containerd can be used without Docker.

For example:

```
Docker
   ↓
containerd
```

but another system can also use:

```
Kubernetes
   ↓
containerd
```

So containerd isn't simply "a Docker program."

It's a general container runtime/lifecycle component used by multiple systems.

### 5. The Execution Layer: runc

Now containerd needs to actually create the container process.

It uses an OCI runtime such as:

```
runc
```

This is where we get very close to the Linux kernel.

Remember from your previous chapters:
- Namespaces
- cgroups
- capabilities

These are Linux kernel primitives.

runc is responsible for configuring the container according to its specification and creating the process using those kernel mechanisms.

Conceptually:

```
containerd
    ↓
  runc
    ↓
Linux Kernel
```

### 6. What does runc actually do?

Suppose containerd tells runc:

"Create this container with this configuration."

runc uses the container configuration to set up things such as:
- PID namespace
- Network namespace
- Mount namespace
- User namespace
- cgroups
- capabilities
- root filesystem

Then it creates the container process.

So if you previously wondered:

"Who actually asks the kernel to create the isolated process?"

At this level, the answer is:

The OCI runtime, commonly runc, performs the low-level container setup and process creation using Linux kernel features.

### 7. What is OCI?

OCI means:

Open Container Initiative

OCI defines standards for containers.

The important one here is the:

OCI Runtime Specification

It describes how a container runtime should receive the configuration of a container and execute it.

This is useful because Docker doesn't have to invent a completely unique container runtime interface.

For example:

```
containerd
    ↓
OCI runtime
    ↓
runc
```

runc is an implementation of the OCI Runtime Specification.

### The complete picture

You should have this architecture in your head:

```
                   USER
                     │
                     │ docker run nginx
                     ↓
              ┌─────────────┐
              │    docker   │
              │     CLI     │
              └──────┬──────┘
                     │
                Docker API
                     │
                     ↓
              ┌─────────────┐
              │   dockerd   │
              │ Docker      │
              │ Daemon      │
              └──────┬──────┘
                     │
                     ↓
              ┌─────────────┐
              │  containerd │
              │             │
              │ lifecycle   │
              └──────┬──────┘
                     │
                     ↓
              ┌─────────────┐
              │    runc     │
              │ OCI runtime │
              └──────┬──────┘
                     │
                     ↓
              ┌─────────────┐
              │ Linux Kernel│
              ├─────────────┤
              │ Namespaces  │
              │ cgroups     │
              │ capabilities│
              └─────────────┘
```

### One important correction to keep in mind

The text uses:

```
Client → Daemon → Supervisor → Runtime
```

These are useful roles, but don't think of them as four completely independent Docker programs that always behave exactly this way.

The modern architecture is more accurately understood as:

```
docker CLI
    ↓
dockerd
    ↓
containerd
    ↓
OCI runtime (runc)
    ↓
Linux kernel
```

Also, containerd itself can perform several responsibilities, including image management and container lifecycle management. The exact internal implementation can vary by Docker/containerd version.

### Brief version for your defense

The Docker Engine is divided into several components. The docker CLI is the client that sends commands to dockerd through the Docker API. dockerd is the high-level Docker daemon that manages images, networks, volumes, and containers. It delegates container lifecycle management to containerd. containerd uses an OCI-compatible runtime such as runc to actually create and start the container process. runc configures Linux kernel features such as namespaces, cgroups, capabilities, and the root filesystem.

### Key things to memorize

```
docker
→ Client / sends API requests

dockerd
→ High-level Docker manager

containerd
→ Container lifecycle manager

runc
→ OCI runtime / creates the container process

OCI
→ Container standards

Linux kernel
→ Provides the actual isolation mechanisms
```

### The best sentence to memorize

### Conclusion

docker sends the request, dockerd manages it, containerd manages the container lifecycle, runc creates the isolated process, and the Linux kernel provides the isolation.

However, an engine is useless without fuel. We understand the machinery that executes the code, but we have not yet examined the code itself. What exactly is a "Docker Image" on the disk? How does a static collection of tarballs transform into a writable, active environment? To answer this, we must look at the file system architecture.

Next Chapter: Images & Containers (Runtime) We will now dissect the anatomy of a Docker image. We will move beyond the high-level concept of "tags" to explore the cryptographic realities of Content Addressable Storage (CAS), the Merkle Tree structure of layers, and the precise mechanics of how a container becomes a writable instance of an immutable blueprint.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------

The important parts for Inception are:

- Image vs Container
- Image layers
- Why layers are useful
- How a container is created from an image
- The writable layer
- Container lifecycle
- PID 1 problem
- ENTRYPOINT vs CMD

Let's go one by one.

## 1. Image vs Container

This is the first thing you absolutely need to understand.

Your file says:

```
Image = build-time artifact
Container = runtime instance
```

Think about it like this:

```
Docker Image
     │
     │ docker run
     ▼
Docker Container
```

### Image

An image is a blueprint.

For example, you build your MariaDB image:

```
FROM debian:bookworm

RUN apt-get update
RUN apt-get install mariadb-server
...
```

After:

```
docker build -t inception-mariadb .
```

you have:

```
inception-mariadb
       │
       ├── Debian filesystem
       ├── MariaDB
       ├── configuration
       ├── scripts
       └── metadata
```

The image itself is not running.

### Container

When you do:

```
docker run inception-mariadb
```

Docker takes the image and creates a running instance from it.

```
                 IMAGE
          inception-mariadb
                  │
                  │ docker run
                  ▼
              CONTAINER
          inception-mariadb
                  │
                  ▼
          mariadbd process
```

You can create multiple containers from the same image:

```
             inception-mariadb
                    │
          ┌─────────┼─────────┐
          ▼         ▼         ▼
      container1 container2 container3
```

They all start from the same image.

### Important distinction

Image = what the container is built from.

Container = the actual running instance.

For your Inception:

```
MariaDB image ──────► MariaDB container
WordPress image ────► WordPress container
NGINX image ────────► NGINX container
```

### Defense

An image is an immutable blueprint containing the filesystem and metadata needed to create a container. A container is a runtime instance of that image.

## 2. Why Docker uses layers

This is also important.

Imagine you have:

```
FROM debian:bookworm

RUN apt-get update
RUN apt-get install nginx
RUN apt-get install openssl
```

Docker doesn't necessarily store the final filesystem as one giant block.

Conceptually:

```
Layer 3 → OpenSSL
Layer 2 → Nginx
Layer 1 → Debian
```

So:

```
┌─────────────────────┐
│ OpenSSL layer       │
├─────────────────────┤
│ Nginx layer         │
├─────────────────────┤
│ Debian layer        │
└─────────────────────┘
```

The important idea is reuse.

Suppose you build another image:

```
FROM debian:bookworm

RUN apt-get install php
```

Docker can reuse the Debian base layer instead of storing another complete Debian filesystem.

```
                 Debian layer
                /            \
               /              \
              ▼                ▼
        Nginx image        PHP image
```

That's why Docker images can share common layers.

## 3. What happens when you modify something?

This is where the immutable idea becomes important.

Suppose your image contains:

```
Debian
   +
Nginx
```

You don't open the existing image and modify it directly.

Instead, you build a new image.

For example:

```
FROM nginx
RUN ...
```

creates another layer.

Conceptually:

Old image:

```
┌─────────────┐
│ Nginx       │
├─────────────┤
│ Debian      │
└─────────────┘
```

New image:

```
┌─────────────┐
│ Your changes│
├─────────────┤
│ Nginx       │
├─────────────┤
│ Debian      │
└─────────────┘
```

This is useful because common layers can be reused.

## 4. What happens when Docker creates your container?

This is very important for understanding Docker.

Suppose you have:

```
docker run nginx
```

Docker has the image:

```
nginx image
```

The image's layers are essentially read-only.

Docker adds a writable layer on top.

```
             Container
        ┌──────────────────┐
        │ Writable layer   │  ← changes made by container
        ├──────────────────┤
        │ Nginx layer      │
        ├──────────────────┤
        │ Debian layer     │
        └──────────────────┘
```

The bottom layers come from the image.

The top layer belongs to the container.

### Example

Inside your container:

```
touch /tmp/test.txt
```

That file is created in the container's writable layer.

If you then destroy the container:

```
docker rm container
```

that writable layer disappears.

So:

```
Container created
       │
       ▼
Writable layer
       │
       ├── file1
       ├── file2
       └── file3
       │
       ▼
Container deleted
       │
       ▼
Writable layer deleted
```

This is why containers are considered ephemeral.

## 5. But what about your Inception volumes?

This is very important for your project.

Your Inception subject requires persistent data using Docker volumes.

For example:

```
MariaDB container
      │
      ├── MariaDB data
      │
      ▼
   Volume
```

The database data should not depend on the container's writable layer.

Why?

Because if you delete the MariaDB container:

```
docker rm mariadb
```

you don't want to lose:

```
WordPress database
users
posts
tables
...
```

So:

```
                 Container
              ┌──────────────┐
              │ MariaDB      │
              └──────┬───────┘
                     │
                     ▼
                MariaDB volume
                     │
                     ▼
              persistent data
```

The container can be destroyed and recreated:

```
Old MariaDB container
        │
        X
        │
        ▼
New MariaDB container
        │
        ▼
same volume
        │
        ▼
same database data
```

### Defense

The container's writable layer is ephemeral. For persistent data, Inception uses Docker named volumes, so the data survives container deletion and recreation.

## 6. Container lifecycle

Your text talks about a container as a state machine.

For your defense, understand these states:

```
Created
   │
   │ start
   ▼
Running
   │
   ├──────────────► Paused
   │                  │
   │                  │ unpause
   │                  ▼
   │               Running
   │
   │ process exits
   ▼
Exited
```

### Created

The container exists, but its main process hasn't started.

Example:

```
docker create nginx
```

You created the container, but didn't start it.

### Running

The container's main process is running.

```
docker start nginx-container
```

For your NGINX container:

```
Container
    │
    ▼
nginx master process
    │
    ▼
Running
```

### Exited

The container's main process stopped.

For example:

```
nginx process
     │
     ▼
   exits
     │
     ▼
container = Exited
```

The container isn't necessarily deleted.

You can inspect it:

```
docker ps -a
```

## 7. The PID 1 problem — VERY IMPORTANT for Inception

You already asked me about this, and this section is directly relevant.

Inside a container, the first process gets:

```
PID 1
```

For example, if your Dockerfile eventually starts:

```
nginx
```

and nginx is the first process:

```
Container PID namespace

PID
 │
 1 ─── nginx
```

This is not the same PID as on the host.

The host might see:

```
PID 2458 → nginx
```

while inside the container:

```
PID 1 → nginx
```

Same process, different PID views.

### Why is PID 1 special?

PID 1 has special responsibilities concerning:

#### 1. Signals

Docker needs to tell your application:

"Please stop."

When you run:

```
docker stop mycontainer
```

Docker normally sends SIGTERM to the container's main process.

Conceptually:

```
docker stop
     │
     ▼
 SIGTERM
     │
     ▼
PID 1
     │
     ▼
application shuts down gracefully
```

Then Docker waits.

If it doesn't stop within the timeout, Docker sends:

```
SIGKILL
```

which forcibly terminates it.

#### 2. Zombie processes

Suppose:

```
PID 1
 │
 └── child process
          │
          ▼
        exits
```

The child can temporarily become a zombie until its exit status is collected with wait().

PID 1 has an important role in adopting/reaping orphaned processes.

For a simple Inception container running one well-behaved service, this may not become a practical problem, but you absolutely should understand the concept for the defense.

## 8. Why systemd doesn't normally manage your container processes

This connects directly to your previous question.

You might think:

```
Host systemd
     │
     ├── nginx container
     ├── mariadb container
     └── wordpress container
```

But that's not how the process hierarchy inside the container works.

Inside the container:

```
Container PID namespace

PID 1
 │
 └── application
```

For example:

MariaDB container:

```
PID 1
 │
 └── mariadbd
```

The host's systemd may manage Docker itself:

```
systemd
   │
   ▼
dockerd
   │
   ▼
containerd
   │
   ▼
container processes
```

But systemd does not become PID 1 inside your container.

That's an important distinction.

## 9. ENTRYPOINT vs CMD

This is another section you should know for Inception.

They have different purposes.

### ENTRYPOINT

Defines the main executable.

Example:

```
ENTRYPOINT ["/entrypoint.sh"]
```

Meaning:

```
Container starts
      │
      ▼
/entrypoint.sh
```

### CMD

Provides default arguments or, when ENTRYPOINT isn't used, can define the default command.

Example:

```
ENTRYPOINT ["/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
```

Conceptually:

```
ENTRYPOINT
     +
CMD
     │
     ▼
/entrypoint.sh nginx -g "daemon off;"
```

The exact behavior depends on whether you use exec-form or shell-form, but for Inception you should generally understand the exec-form pattern.

## 10. Why nginx -g "daemon off;" matters

This is particularly relevant to your NGINX container.

Normally NGINX is designed as a daemon and may background itself.

But Docker needs the main application to remain attached to the container's foreground process.

So commonly:

```
nginx -g "daemon off;"
```

means:

Start NGINX but don't daemonize; keep it in the foreground.

Then:

```
Container
   │
   └── PID 1
         │
         └── nginx
               │
               └── stays running
```

If the main process exits:

```
nginx exits
    │
    ▼
container exits
```

This is a very important Docker concept:

The lifetime of the container is tied to its main process.

## What you DON'T need for Inception

From your document, I would skip these for now:

❌ Deep CAS internals
- Content Addressable Storage
- SHA256 blobs

Interesting, but not important for your Inception defense.

❌ OCI index.json
- oci-layout
- index.json
- blobs/sha256/

You don't need to manually inspect these.

❌ Merkle tree details

You can know that Docker images use content-addressed layers, but you don't need to explain the mathematical structure of Merkle trees.

❌ Manually extracting an image
- docker save
- tar -xf
- cat index.json

Not necessary for Inception.

## What you SHOULD memorize for Inception

### Image

An image is an immutable blueprint used to create containers. It contains filesystem layers and metadata.

### Container

A container is a runtime instance of an image, with its own writable layer and isolated environment.

### Layers

Docker images are composed of layers, which can be reused between images to save storage and speed up builds and transfers.

### Writable layer

A container gets a writable layer on top of the image's read-only layers. Changes in this layer are lost when the container is removed.

### Volume

A Docker volume stores persistent data outside the container's ephemeral writable layer, so data survives container recreation.

### PID 1

The first process inside a container is PID 1. It has special responsibilities for signal handling and reaping orphaned child processes.

### Container lifecycle

A container can be Created, Running, Paused, or Exited. The container's lifecycle is closely tied to its main process.

### ENTRYPOINT / CMD

ENTRYPOINT defines the main executable, while CMD provides default arguments or a default command when no ENTRYPOINT is used.

## 🧠 The whole lesson in one picture

```
                 DOCKER IMAGE
              ┌─────────────────┐
              │ Metadata        │
              ├─────────────────┤
              │ Layer 3         │
              ├─────────────────┤
              │ Layer 2         │
              ├─────────────────┤
              │ Layer 1         │
              └────────┬────────┘
                       │
                  docker run
                       │
                       ▼
              ┌─────────────────┐
              │ Container       │
              ├─────────────────┤
              │ Writable layer  │
              ├─────────────────┤
              │ Image layers    │
              └────────┬────────┘
                       │
                       ▼
                    PID 1
                       │
              ┌────────┼────────┐
              ▼        ▼        ▼
             nginx  php-fpm  mariadbd
```

And for persistent Inception data:

```
Container
    │
    │
    ▼
Named Volume
    │
    ▼
Persistent data
```

The main idea you should leave this lesson with is:

The image is the immutable template, the container is the running instance, the writable layer contains temporary changes, volumes preserve important data, and PID 1 is responsible for the main process inside the container.