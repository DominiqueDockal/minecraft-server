# Minecraft Server with Docker

This repository provides a custom Docker-based setup for running a Minecraft Java server. It includes a custom `Dockerfile`, a `docker-compose.yaml` service definition, a startup script that writes the EULA file, and a Docker-managed named volume for persistent server data.

## Table of Contents
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Environment configuration](#environment-configuration)
- [Quickstart](#quickstart)
- [Usage](#usage)
- [Configuration](#configuration)
- [Testing](#testing)

## Repository Structure

```text
.
├── Dockerfile
├── docker-compose.yaml
├── entrypoint.sh
├── README.md
├── example.env
└── .gitignore
```

## Prerequisites

Before starting the project, make sure the following are available:

- Docker Desktop or Docker Engine with Docker Compose support.
- A downloaded Minecraft Java server binary named `server.jar`.
- Python and `pip` only if you want to run the optional connectivity test with `mcstatus`.

Official Minecraft Java server download:
- [Minecraft Java Server Download](https://www.minecraft.net/de-de/download)

## Environment configuration

This project uses a `.env` file for configuration. Start by copying the example file:

```bash
cp example.env .env
```

Then adjust the values (for example `EULA`, `HOST_PORT`, `MEMORY`) in `.env` before running `docker compose up --build`. The `.env` file is ignored by git so that local configuration and potential secrets are not committed.

> [!WARNING]
> Never commit your `.env` file to the repository. It may contain sensitive configuration values that should only exist on your local machine or deployment environment.

## Quickstart

1. Clone this repository to your machine:

   ```bash
   git clone https://github.com/DominiqueDockal/minecraft-server.git
   cd minecraft-server
   ```

2. Copy the example environment file and adjust the values:

   ```bash
   cp example.env .env
   # edit .env and set EULA, HOST_PORT, MEMORY as needed
   ```

3. Download the Minecraft Java server binary and place `server.jar` in the project root.

4. Start the service:

   ```bash
   docker compose up --build
   ```

5. Wait until the logs show that the server is starting.

6. The startup script writes the EULA file automatically to `/data/eula.txt` inside the container. The `/data` directory is backed by a Docker-managed named volume so that server data persists across container restarts and recreation.

7. When the logs show `Done (...)! For help, type "help"`, the server is ready.

8. Connect to the server on the configured host port from `.env` (for example `8888` by default).

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

### Remove containers and named volumes
```bash
docker compose down -v
```

This removes the container and the Docker-managed named volume. As a result, world data and generated server files stored in the volume are deleted unless they were backed up separately.

## Configuration

### Current setup
The current configuration uses these main settings:

- Container port: `25565`
- Published host port: configurable through `HOST_PORT` (default: `8888`)
- Data directory inside the container: `/data`
- Docker-managed named volume for persistent server data
- Restart policy: `unless-stopped`
- Java heap: configurable through `MEMORY` (default: `1G`)
- EULA handling through the `EULA` environment variable and the startup script

### Port mapping
Inside the container, Minecraft listens on port `25565`. Docker Compose publishes that port on the host through the `HOST_PORT` variable from `.env`.

Example `.env`:
```env
HOST_PORT=8888
```

Example Compose configuration:
```yaml
ports:
  - "${HOST_PORT}:25565"
```

If you want to expose the server on a different host port, change the value of `HOST_PORT` in `.env`.

Example:
```env
HOST_PORT=25565
```

With that change, clients would connect to `localhost:25565` or `SERVER_IP:25565`.

### Memory configuration
The startup script starts Java with heap settings based on the `MEMORY` environment variable.

```sh
MEMORY_VALUE=${MEMORY:-"1G"}
exec java -Xmx${MEMORY_VALUE} -Xms${MEMORY_VALUE} -jar /opt/minecraft/server.jar nogui
```

You can increase or reduce memory depending on the available RAM of the host system.

Examples:
- Smaller VM:
```env
MEMORY=512M
```

- Larger VM:
```env
MEMORY=2G
```

The default `1G` value is a practical compromise for smaller machines and helps keep container startup reliable.

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
- If `EULA` is set in `.env`, that value is written.
- If `EULA` is not set, the script falls back to `true`.
- The generated file is stored in the persistent `/data` directory inside the named volume.

Example `.env`:
```env
EULA=true
```

This setup keeps the default behavior in one place and avoids unnecessary duplication in the Dockerfile.

### Persistence
The server runs with `/data` as its working directory, and Docker Compose attaches a Docker-managed named volume to that path.

Example Compose configuration:
```yaml
volumes:
  - mc-data:/data
```

As a result, generated files such as `eula.txt`, `server.properties`, logs, libraries, and world data remain available after container restarts or container recreation, as long as the named volume is not removed.

### Restart behavior
The service uses:

```yaml
restart: unless-stopped
```

This ensures that the container is started again automatically after unexpected termination unless it was explicitly stopped by the user.

### Cloud VM and firewall note
If the server is meant to be reachable from the internet, the configured host port from `.env` must not only be published in Docker Compose but also be allowed by the cloud firewall or VM security rules. Without this external port allowance, the service may work locally but still be unreachable from outside the machine.

## Testing

The following checks can be used locally or on a remote Linux server. For local tests, use `localhost:<HOST_PORT>`. For remote tests, use `SERVER_IP:<HOST_PORT>`, replacing `<HOST_PORT>` with the configured value from `.env`.

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
- `localhost:<HOST_PORT>` for local testing on the same machine
- `SERVER_IP:<HOST_PORT>` for testing on a remote server

Replace `<HOST_PORT>` with the value configured in `.env` (for example `8888`).

If the server appears online and you can join it, the deployment works correctly.

### 3. Script-based connectivity check
Install `mcstatus`:

```bash
python -m pip install mcstatus
```

Run a status query, replacing `<HOST_PORT>` with your configured host port:

```bash
python -c "from mcstatus import JavaServer; server = JavaServer.lookup('localhost:<HOST_PORT>'); status = server.status(); print(f'Online players: {status.players.online}, latency: {status.latency} ms')"
```

For a remote system, replace `localhost` with the public server IP. If the command returns latency information, the server is reachable.

### 4. Persistence check
1. Start the server and wait until files are created in `/data` inside the container.
2. Restart the service:

```bash
docker compose restart mc-server
```

3. Verify that files such as `eula.txt`, `server.properties`, logs, libraries, and world data still exist in the named volume.

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