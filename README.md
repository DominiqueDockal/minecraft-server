# Minecraft Server with Docker

This repository provides a custom Docker-based setup for running a Minecraft Java server. It includes a custom `Dockerfile`, a `docker-compose.yaml` service definition, a startup script that writes the EULA file, and a bind mount for persistent server data. 

## Table of Contents
- [Repository Description](#repository-description)
- [Repository Structure](#repository-structure)
- [Requirements](#requirements)
- [Quickstart](#quickstart)
- [Usage](#usage)
- [Configuration](#configuration)
- [Testing](#testing)

## Repository Description
This repository contains everything needed to build and run a Minecraft Java server in Docker. Its purpose is to provide a reproducible setup with persistent world data, automatic restart behavior, and simple runtime configuration through environment variables and Compose settings. 

## Repository Structure
```text
.
├── Dockerfile
├── docker-compose.yaml
├── entrypoint.sh
├── README.md
└── .gitignore
```

### Important Files
- `Dockerfile` builds a custom image for the Minecraft Java server instead of using a prebuilt Minecraft image. 
- `docker-compose.yaml` defines the `mc-server` service, port mapping, restart behavior, environment variables, and bind mount. 
- `entrypoint.sh` writes the EULA setting into `/data/eula.txt` and then starts the server. 
- `.gitignore` should exclude irrelevant and generated files such as `server.jar` and local runtime data. 

## Requirements
Before starting the project, make sure the following are available:

- Docker Desktop or Docker Engine with Docker Compose support.
- A downloaded Minecraft Java server binary named `server.jar`.
- Python and `pip` only if you want to run the optional connectivity test with `mcstatus`. 

Official Minecraft Java server download:
- [Minecraft Java Server Download](https://www.minecraft.net/de-de/download)

## Quickstart
1. Clone or copy this repository to your machine.
2. Download the Minecraft Java server binary and place `server.jar` in the project root.
3. Start the service:

```bash
docker compose up --build
```

4. Wait until the logs show that the server is starting.
5. The startup script writes the EULA file automatically to `data/eula.txt`.
6. When the logs show `Done (...)! For help, type "help"`, the server is ready.
7. Connect to the server on port `8888` from the host system. 

## Usage

### Start the server
```bash
docker compose up --build
```

### Start the server in the background
```bash
docker compose up -d --build
```

### Stop the server
```bash
docker compose down
```

### Restart the server
```bash
docker compose restart mc-server
```

### Show logs
```bash
docker compose logs -f mc-server
```

### Remove containers
```bash
docker compose down
```

### Remove containers and anonymous resources created by Compose
```bash
docker compose down -v
```

The bind-mounted `data/` directory remains on the host unless it is deleted manually, so world data and generated server files are preserved separately from the container lifecycle. 

## Configuration

### Current setup
The current configuration uses these main settings:

- Container port: `25565`
- Published host port: `8888`
- Data directory inside the container: `/data`
- Host bind mount: `./data:/data`
- Restart policy: `unless-stopped`
- Java heap: `-Xms1G -Xmx1G`
- EULA handling through the `EULA` environment variable and the startup script. 

### Why the base image is sufficient
The image is built from `amazoncorretto`, which already provides a suitable Java runtime for launching the Minecraft server JAR. Because the project only needs Java to execute `server.jar`, no additional OS packages are required for the basic server startup. 

### Port mapping
Inside the container, Minecraft listens on port `25565`. Docker Compose publishes that port on host port `8888`, so clients connect to the host on port `8888`. 

Example:
```yaml
ports:
  - "8888:25565"
```

If you want to expose the server on a different host port, change only the left side.

Example:
```yaml
ports:
  - "25565:25565"
```

With that change, clients would connect to `localhost:25565` or `SERVER_IP:25565`. 

### Memory configuration
The startup script currently starts Java with fixed heap settings:

```sh
exec java -Xmx1G -Xms1G -jar /opt/minecraft/server.jar nogui
```

You can increase or reduce memory depending on the available RAM of the host system.

Examples:
- Smaller VM:
```sh
exec java -Xmx512M -Xms512M -jar /opt/minecraft/server.jar nogui
```

- Larger VM:
```sh
exec java -Xmx2G -Xms2G -jar /opt/minecraft/server.jar nogui
```

The current `1G` values are a practical compromise for smaller machines and help keep container startup reliable.

### Replacing the server JAR
The image copies `server.jar` from the repository root into `/opt/minecraft/server.jar` during the build.

```dockerfile
COPY server.jar /opt/minecraft/server.jar
```

If you want to use a different server binary, replace the file in the repository root before rebuilding the image. Then run:

```bash
docker compose up --build
```

This rebuild is required because the JAR is baked into the image. 

### EULA behavior
The startup script writes the EULA file dynamically at container start:

```sh
EULA_VALUE=${EULA:-"true"}
echo "eula=${EULA_VALUE}" > /data/eula.txt
```

This means:
- If `EULA` is set in Compose, that value is written.
- If `EULA` is not set, the script falls back to `true`.
- The generated file is stored in the persistent `data/` directory. 

Example Compose configuration:
```yaml
environment:
  EULA: "true"
```

This setup keeps the default behavior in one place and avoids unnecessary duplication in the Dockerfile. 

### Persistence
The server runs with `/data` as its working directory, and Docker Compose mounts `./data` from the host into that path.

```yaml
volumes:
  - ./data:/data
```

As a result, generated files such as `eula.txt`, `server.properties`, logs, libraries, and world data remain available after container restarts or recreation. 

### Restart behavior
The service uses:

```yaml
restart: unless-stopped
```

This ensures that the container is started again automatically after unexpected termination unless it was explicitly stopped by the user. 

### Cloud VM and firewall note
If the server is meant to be reachable from the internet, port `8888` must not only be published in Docker Compose but also be allowed by the cloud firewall or VM security rules. Without this external port allowance, the service may work locally but still be unreachable from outside the machine. 

## Testing

The following checks can be used locally or on a remote Linux server. For local tests, use `localhost:8888`. For remote tests, use `SERVER_IP:8888`. 

### 1. Check startup logs
```bash
docker compose logs -f mc-server
```

A successful startup should end with a message similar to:

```text
Done (...)! For help, type "help"
```

### 2. Connect with Minecraft Java Edition
Open Minecraft Java Edition and add a multiplayer server.

Use one of these addresses:
- `localhost:8888` for local testing on the same machine
- `SERVER_IP:8888` for testing on a remote server 

If the server appears online and you can join it, the deployment works correctly.

### 3. Script-based connectivity check
Install `mcstatus`:

```bash
python -m pip install mcstatus
```

Run a status query:

```bash
python -c "from mcstatus import JavaServer; server = JavaServer.lookup('localhost:8888'); status = server.status(); print(f'Online players: {status.players.online}, latency: {status.latency} ms')"
```

For a remote system, replace `localhost` with the public server IP. If the command returns latency information, the server is reachable. 

### 4. Persistence check
1. Start the server and wait until files are created in `data/`.
2. Restart the service:

```bash
docker compose restart mc-server
```

3. Verify that files such as `eula.txt`, `server.properties`, logs, libraries, and world data still exist in `data/`.

### 5. Restart behavior check
Simulate an unexpected container stop:

```bash
docker exec mc-server sh -c "kill 1"
```

Then inspect the service:

```bash
docker compose ps
```

You can also review the logs again:

```bash
docker compose logs -f mc-server
```

A correct result is that the container starts again automatically and the server reaches the normal `Done (...)! For help, type "help"` state. 