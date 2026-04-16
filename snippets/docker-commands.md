# Docker CLI Command Snippets

## Purpose

This reference provides quick, copy-pasteable Docker CLI one-liners for common container operations. These snippets are designed for daily development and debugging tasks.

## When to use

Use these snippets when:
- Managing Docker images and containers
- Debugging container issues
- Cleaning up unused resources
- Inspecting container state

## Prerequisites

- Docker Engine >= 20.10 installed
- Docker CLI in PATH

## Common Operations

### Container Management

```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# List containers with size
docker ps -s

# Start a stopped container
docker start <container_id_or_name>

# Stop a running container
docker stop <container_id_or_name>

# Restart a container
docker restart <container_id_or_name>

# Remove a stopped container
docker rm <container_id_or_name>

# Remove all stopped containers
docker container prune -f

# View container logs
docker logs -f <container_id_or_name>

# Follow container logs with timestamps
docker logs -f -t <container_id_or_name>

# Inspect container details
docker inspect <container_id_or_name>

# Execute command in running container
docker exec -it <container_id_or_name> /bin/sh

# Copy file from container
docker cp <container_id_or_name>:/path/to/file ./local/path
```

### Image Management

```bash
# List Docker images
docker images

# List images with size
docker images -s

# Pull an image
docker pull <image_name>:<tag>

# Remove an image
docker rmi <image_id_or_name>

# Remove unused images
docker image prune -a -f

# Build an image from Dockerfile
docker build -t <image_name>:<tag> .

# Build with no cache
docker build --no-cache -t <image_name>:<tag> .

# Tag an image
docker tag <source_image> <target_image>

# Push image to registry
docker push <image_name>:<tag>
```

### Networking

```bash
# List networks
docker network ls

# Inspect a network
docker network inspect <network_name>

# Create a network
docker network create <network_name>

# Remove a network
docker network rm <network_name>

# Connect container to network
docker network connect <network_name> <container_name>

# Disconnect container from network
docker network disconnect <network_name> <container_name>
```

### Volumes

```bash
# List volumes
docker volume ls

# Inspect a volume
docker volume inspect <volume_name>

# Create a volume
docker volume create <volume_name>

# Remove a volume
docker volume rm <volume_name>

# Remove unused volumes
docker volume prune -f
```

### Docker Compose

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Rebuild services
docker compose up -d --build

# Scale a service
docker compose up -d --scale <service_name>=<replicas>
```

### System Information

```bash
# Docker system info
docker info

# Disk usage
docker system df

# Detailed disk usage
docker system df -v

# Clean up unused data
docker system prune -af
```

### Health and Debugging

```bash
# Container CPU/memory stats
docker stats

# All container stats (no streaming)
docker stats --no-stream

# Inspect container processes
docker top <container_name>

# Container event stream
docker events

# Dockerfile used to build image
docker history <image_name>
```

### Security

```bash
# Scan image for vulnerabilities (requires Docker Scout or Trivy)
docker scout cves <image_name>

# List capabilities
docker inspect --format '{{.HostConfig.CapAdd}}' <container>

# Check for privileged container
docker inspect --format '{{.HostConfig.Privileged}}' <container>
```

## Verify

All commands can be tested in a local Docker environment. Run `docker --version` to verify Docker is installed.

## Rollback

N/A — these are read-only inspection and management commands.

## Common errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Cannot connect to Docker daemon` | Docker not running | Start Docker daemon: `sudo systemctl start docker` |
| `No such container` | Container doesn't exist | Run `docker ps -a` to list all containers |
| `No such image` | Image not found locally | Pull the image: `docker pull <image>` |
| `Conflict: resource already exists` | Resource with same name | Use a different name or remove existing resource |

## References

- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [Docker Compose CLI Reference](https://docs.docker.com/compose/reference/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
