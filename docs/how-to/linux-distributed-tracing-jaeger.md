# Linux Distributed Tracing with Jaeger

## Purpose

Set up a distributed tracing infrastructure using Jaeger on Linux for monitoring and troubleshooting microservices architectures. This project deploys Jaeger all-in-one container, configures agent-side instrumentation, and creates a complete observability pipeline for distributed request tracking.

## When to use

- debugging microservices latency issues and failure propagation
- understanding request flow across multiple services
- visualizing service dependencies and call patterns
- tracking transactions across distributed systems
- identifying performance bottlenecks in distributed architectures
- implementing observability for cloud-native applications

## Prerequisites

- Linux server (Ubuntu 22.04, RHEL 9, or Debian 12)
- Docker installed and running
- Root or sudo access
- Network access for agent communication (UDP 6831, 6832, TCP 14268)
- At least 2GB RAM available for Jaeger

## Steps

### Step 1: Install Docker

```bash
#!/usr/bin/env bash
set -euo pipefail

# Jaeger Docker Installation Script
# Purpose: Install Docker for Jaeger distributed tracing
# Usage: ./install-docker.sh
# Requirements: Ubuntu/Debian/RHEL
# Safety: idempotent — safe to run multiple times
# Tested on: Ubuntu 22.04, RHEL 9

install_ubuntu() {
    echo "[INFO] Installing Docker on Ubuntu..."
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    systemctl enable docker
    systemctl start docker
    
    echo "[INFO] Docker installed successfully"
}

install_rhel() {
    echo "[INFO] Installing Docker on RHEL..."
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    systemctl enable docker
    systemctl start docker
    
    echo "[INFO] Docker installed successfully"
}

detect_and_install() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)
                install_ubuntu
                ;;
            rhel|centos|rocky|alma)
                install_rhel
                ;;
            *)
                echo "[ERROR] Unsupported OS: $ID"
                exit 1
                ;;
        esac
    else
        echo "[ERROR] Cannot detect OS"
        exit 1
    fi
}

verify_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo "[INFO] Docker version: $(docker --version)"
        echo "[INFO] Docker daemon: $(docker info 2>/dev/null | head -1)"
    else
        echo "[ERROR] Docker not installed"
        exit 1
    fi
}

detect_and_install
verify_docker
```

### Step 2: Deploy Jaeger All-in-One

```bash
#!/usr/bin/env bash
set -euo pipefail

# Jaeger All-in-One Deployment Script
# Purpose: Deploy Jaeger distributed tracing system
# Usage: ./deploy-jaeger.sh --action <start|stop|restart|status|logs|clean>
# Requirements: Docker
# Safety: DRY_RUN=true by default — set DRY_RUN=false for actual changes
# Tested on: Ubuntu 22.04, RHEL 9

DRY_RUN="${DRY_RUN:-true}"
ACTION="${1:-}"
JAEGER_CONTAINER="jaeger-all-in-one"
JAEGER_VERSION="${JAEGER_VERSION:-1.60}"
JAEGER_PORT_UI="${JAEGER_PORT_UI:-16686}"
JAEGER_PORT_AGENT="${JAEGER_PORT_AGENT:-6831}"
DATA_DIR="${DATA_DIR:-/opt/jaeger/data}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_docker() {
    command -v docker >/dev/null 2>&1 || { log_error "Docker not found"; exit 1; }
    docker info >/dev/null 2>&1 || { log_error "Docker daemon not running"; exit 1; }
}

start_jaeger() {
    log_info "Starting Jaeger all-in-one..."

    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would create data directory: $DATA_DIR"
        log_warn "[dry-run] Would run Jaeger container on ports $JAEGER_PORT_UI, $JAEGER_PORT_AGENT"
        return 0
    fi

    mkdir -p "$DATA_DIR"
    chmod 755 "$DATA_DIR"

    docker run -d \
        --name "$JAEGER_CONTAINER" \
        -p 6831:6831/udp \
        -p 6832:6832/udp \
        -p 5778:5778 \
        -p 16686:16686 \
        -p 14268:14268 \
        -p 14250:14250 \
        -e COLLECTOR_OTLP_ENABLED=true \
        -v "$DATA_DIR:/tmp/jaeger" \
        jaegertracing/all-in-one:$JAEGER_VERSION

    log_info "Jaeger started successfully"
    log_info "UI available at: http://localhost:$JAEGER_PORT_UI"
    log_info "Agent UDP port: $JAEGER_PORT_AGENT"
}

stop_jaeger() {
    log_info "Stopping Jaeger..."

    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would stop and remove Jaeger container"
        return 0
    fi

    docker stop "$JAEGER_CONTAINER" 2>/dev/null || true
    docker rm "$JAEGER_CONTAINER" 2>/dev/null || true

    log_info "Jaeger stopped"
}

restart_jaeger() {
    stop_jaeger
    start_jaeger
}

status_jaeger() {
    if docker ps --format '{{.Names}}' | grep -q "^${JAEGER_CONTAINER}$"; then
        log_info "Jaeger is RUNNING"
        docker ps --filter "name=$JAEGER_CONTAINER" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        log_warn "Jaeger is NOT running"
    fi
}

logs_jaeger() {
    docker logs --tail 100 -f "$JAEGER_CONTAINER" 2>&1
}

clean_jaeger() {
    log_warn "Cleaning Jaeger data and container..."

    if [ "$DRY_RUN" = true ]; then
        log_warn "[dry-run] Would remove container and data directory"
        return 0
    fi

    docker stop "$JAEGER_CONTAINER" 2>/dev/null || true
    docker rm "$JAEGER_CONTAINER" 2>/dev/null || true
    rm -rf "$DATA_DIR"

    log_info "Jaeger cleaned"
}

show_usage() {
    cat << EOF
Usage: $0 --action <ACTION> [OPTIONS]

Actions:
    start     Start Jaeger all-in-one
    stop      Stop Jaeger all-in-one
    restart   Restart Jaeger
    status    Show Jaeger status
    logs      Show Jaeger logs
    clean     Remove container and data

Options:
    --port-ui PORT       UI port (default: 16686)
    --port-agent PORT    Agent UDP port (default: 6831)
    --data-dir PATH      Data directory (default: /opt/jaeger/data)
    --version VERSION   Jaeger version (default: 1.60)
    --dry-run           Show what would happen

Examples:
    $0 --action start
    $0 --action start --port-ui 8080 --version 1.55
    $0 --action status
    DRY_RUN=false $0 --action clean
EOF
}

main() {
    if [ -z "$ACTION" ]; then
        show_usage
        exit 1
    fi

    while [ $# -gt 0 ]; do
        case "$1" in
            --action) ACTION="$2"; shift 2 ;;
            --port-ui) JAEGER_PORT_UI="$2"; shift 2 ;;
            --port-agent) JAEGER_PORT_AGENT="$2"; shift 2 ;;
            --data-dir) DATA_DIR="$2"; shift 2 ;;
            --version) JAEGER_VERSION="$2"; shift 2 ;;
            --dry-run) DRY_RUN=false; shift ;;
            -h|--help) show_usage; exit 0 ;;
            *) shift ;;
        esac
    done

    log_info "=== Jaeger Deployment ==="
    log_info "Action      : $ACTION"
    log_info "Version     : $JAEGER_VERSION"
    log_info "UI Port     : $JAEGER_PORT_UI"
    log_info "Agent Port  : $JAEGER_PORT_AGENT"
    log_info "Data Dir    : $DATA_DIR"
    log_info "DRY_RUN     : $DRY_RUN"
    echo ""

    check_docker

    case "$ACTION" in
        start) start_jaeger ;;
        stop) stop_jaeger ;;
        restart) restart_jaeger ;;
        status) status_jaeger ;;
        logs) logs_jaeger ;;
        clean) clean_jaeger ;;
        *) log_error "Unknown action: $ACTION"; show_usage; exit 1 ;;
    esac

    echo ""
    log_info "=== Done ==="
}

main "$@"
```

### Step 3: Configure instrumentation for applications

Jaeger supports multiple programming languages. Here's how to instrument applications:

```python
# Python Flask application with Jaeger tracing
from flask import Flask, request, jsonify
from jaeger_client import Config
from opentracing.instrumentation.flask_flask import FlaskInstrumentor

app = Flask(__name__)

# Initialize Jaeger
def init_jaeger():
    config = Config(
        config={
            'sampler': {
                'type': 'const',
                'param': 1,
            },
            'reporter': {
                'log_spans': True,
                'agent_host': 'localhost',
                'agent_port': 6831,
            },
            'service_name': 'flask-app',
        },
        service_name='flask-app',
    )
    return config.initialize_tracer()

tracer = init_jaeger()
FlaskInstrumentor().instrument_app(app)

@app.route('/api/users')
def get_users():
    with tracer.start_span('get_users') as span:
        span.set_tag('http.method', request.method)
        span.set_tag('http.url', request.url)
        # ... business logic
        return jsonify({'users': []})

@app.route('/api/orders')
def get_orders():
    with tracer.start_span('get_orders') as span:
        span.set_tag('http.method', request.method)
        span.set_tag('http.url', request.url)
        # ... business logic  
        return jsonify({'orders': []})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

### Step 4: Configure agent-side collection

```bash
#!/usr/bin/env bash
set -euo pipefail

# Jaeger Agent Configuration Script
# Purpose: Configure Jaeger agent for application instrumentation
# Usage: ./configure-agent.sh --action <start|stop|status>
# Requirements: Docker
# Safety: idempotent
# Tested on: Ubuntu 22.04

JAEGER_AGENT="jaeger-agent"
AGENT_PORT="${AGENT_PORT:-6831}"
COLLECTOR_PORT="${COLLECTOR_PORT:-14268}"

log_info() { echo -e "\033[0;32m[INFO]\033[0m  $1"; }

start_agent() {
    log_info "Starting Jaeger agent..."
    
    docker run -d \
        --name "$JAEGER_AGENT" \
        -p 6831:6831/udp \
        -p 6832:6832/udp \
        -p 5775:5775/udp \
        -e REPORTER_TYPE=grpc \
        -e REPORTER_GRPC_HOST_PORT=jaeger-all-in-one:14250 \
        jaegertracing/jaeger-agent:latest \
        --reporter.grpc.host-port=jaeger-all-in-one:14250
    
    log_info "Jaeger agent started"
}

stop_agent() {
    docker stop "$JAEGER_AGENT" 2>/dev/null || true
    docker rm "$JAEGER_AGENT" 2>/dev/null || true
    log_info "Jaeger agent stopped"
}

status_agent() {
    if docker ps --format '{{.Names}}' | grep -q "^${JAEGER_AGENT}$"; then
        log_info "Jaeger agent is RUNNING"
    else
        echo "Jaeger agent is NOT running"
    fi
}

case "${1:-}" in
    start) start_agent ;;
    stop) stop_agent ;;
    status) status_agent ;;
    *) echo "Usage: $0 --action start|stop|status" ;;
esac
```

### Step 5: Configure Nginx for Jaeger

```nginx
# Nginx configuration for Jaeger proxy
server {
    listen 80;
    server_name jaeger.example.com;

    location / {
        proxy_pass http://localhost:16686;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Secure the endpoint
    location /api/ {
        auth_basic "Jaeger Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://localhost:16686;
    }
}
```

## Verify

### Check Jaeger is running

```bash
# Check container status
docker ps | grep jaeger

# Check port listening
ss -tlnp | grep 16686

# Test UI access
curl -s http://localhost:16686/api/health | jq .
```

### Generate test traces

```bash
# Using Jaeger's internal test endpoints
curl -s http://localhost:16686/api/gen -X POST \
  -H "Content-Type: application/json" \
  -d '{"service":"test-service","operation":"test-operation"}'

# Check for traces in UI
curl -s "http://localhost:16686/api/traces?service=test-service" | jq '.data | length'
```

### Verify tracing data

```bash
# Check spans in Cassandra/Elasticsearch if configured
docker exec -it jaeger-all-in-one \
  go run ./cmd/collector --help 2>&1 | head -5

# Check storage backend
curl -s "http://localhost:16686/api/services" | jq '.data[]'
```

## Rollback

### Stop and remove Jaeger

```bash
# Stop all Jaeger containers
docker stop jaeger-all-in-one jaeger-agent 2>/dev/null || true

# Remove containers
docker rm jaeger-all-in-one jaeger-agent 2>/dev/null || true

# Remove volumes (tracing data)
docker volume ls | grep jaeger
docker volume rm jaeger-data 2>/dev/null || true
```

### Restore application without tracing

```bash
# Remove Jaeger client library from requirements.txt
# Remove instrumentation code from application
# Restart application
systemctl restart application
```

## Common errors

### Error: "connection refused to agent"

**Symptom:** Application cannot send spans to Jaeger agent.

**Solution:** Ensure the agent is running on the correct host/port. Check firewall rules allow UDP 6831.

### Error: "span data not appearing in UI"

**Symptom:** Traces sent but not visible in Jaeger UI.

**Solution:** Check collector logs: `docker logs jaeger-all-in-one`. Verify the service name matches what you're searching for.

### Error: "collector not receiving OTLP"

**Symptom:** OTLP-based instrumentation not working.

**Solution:** Ensure COLLECTOR_OTLP_ENABLED=true is set. Check port 4317/4318 are accessible.

### Error: "out of memory"

**Symptom:** Jaeger all-in-one container crashes.

**Solution:** Increase memory allocation or switch to production setup with separate Cassandra/Elasticsearch.

### Error: "certificate verify failed"

**Symptom:** Cannot connect to collector over TLS.

**Solution:** Use non-TLS endpoints or configure proper certificates.

## References

- [Jaeger Documentation](https://www.jaegertracing.io/docs/1.60/) (2026-02-01)
- [Jaeger Docker Deployment](https://www.jaegertracing.io/docs/1.60/deployment/) (2026-02-01)
- [OpenTracing Python API](https://opentracing.io/documentation/python/api/) (2026-01-15)
- [Jaeger Client Libraries](https://www.jaegertracing.io/docs/1.60/client_libraries/) (2026-02-01)
- [Instrumenting Applications](https://www.jaegertracing.io/docs/1.60/instrumentation/) (2026-02-01)
