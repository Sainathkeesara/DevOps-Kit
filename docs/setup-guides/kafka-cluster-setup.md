# Kafka Cluster Setup (Single Broker for Development)

## Purpose

This guide provides step-by-step instructions for setting up a single-broker Apache Kafka cluster suitable for local development and testing. It covers installation, configuration, verification, and basic operational tasks.

## When to use

- Setting up a local Kafka environment for development
- Learning Kafka concepts and operations
- Testing applications that integrate with Kafka
- Building CI/CD pipelines that require Kafka
- Quick prototyping without infrastructure overhead

## Prerequisites

### Required Tools
- Java 11+ (Kafka requires JVM)
- curl or wget for downloading Kafka
- Minimum 4GB RAM available (Kafka is memory-intensive)
- 10GB free disk space

### Operating System
- Linux (Ubuntu 22.04, CentOS 8+, Debian 11+)
- macOS 12+ (Intel or Apple Silicon)
- Windows via WSL2

## Steps

### 1. Install Java

Kafka requires Java. Install OpenJDK 11 or 17:

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y openjdk-17-jdk

# Verify Java installation
java -version
```

### 2. Download Kafka

Download Kafka from Apache archives:

```bash
# Create working directory
mkdir -p ~/kafka && cd ~/kafka

# Download Kafka 3.8.0 (latest stable as of this guide)
KAFKA_VERSION="3.8.0"
curl -fsSL "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_2.13-${KAFKA_VERSION}.tgz" | tar xz

# Navigate to Kafka directory
cd kafka_2.13-${KAFKA_VERSION}
```

### 3. Configure Single Broker

Edit the broker configuration:

```bash
# Backup default config
cp config/kraft/server.properties config/kraft/server.properties.bak

# Edit broker settings
cat >> config/kraft/server.properties << 'EOF'

# Single broker configuration
listeners=PLAINTEXT://localhost:9092
advertised.listeners=PLAINTEXT://localhost:9092

# Log retention (development: keep logs shorter)
log.retention.hours=24
log.retention.check.interval.ms=300000

# Log segment (smaller for development)
log.segment.bytes=107374182

# Partition counts
num.partitions=1

# ZooKeeper timeout
zookeeper.connection.timeout.ms=18000
EOF
```

### 4. Format Storage (KRaft Mode)

Kafka 3.x uses KRaft mode (no ZooKeeper required):

```bash
# Generate cluster UUID
KAFKA_CLUSTER_ID=$(bin/kafka-storage.sh random-uuid)

# Format storage directories
bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c config/kraft/server.properties
```

### 5. Start Kafka Broker

Start the Kafka broker:

```bash
# Start broker in background
bin/kafka-server-start.sh -daemon config/kraft/server.properties

# Check if broker is running
ps aux | grep kafka
```

### 6. Verify Broker is Running

Test broker connectivity:

```bash
# List topics (should be empty initially)
bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Create a test topic
bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --create --topic test-topic \
  --partitions 1 --replication-factor 1

# Verify topic created
bin/kafka-topics.sh --bootstrap-server localhost:9092 \
  --describe --topic test-topic
```

### 7. Test Message Production and Consumption

Test the complete message flow:

```bash
# Start a console consumer (in background or new terminal)
bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic test-topic \
  --from-beginning &
CONSUMER_PID=$!

# Produce test messages
echo -e "message-1\nmessage-2\nmessage-3" | \
  bin/kafka-console-producer.sh \
    --bootstrap-server localhost:9092 \
    --topic test-topic

# Verify messages received (wait a few seconds)
sleep 2

# Cleanup
kill $CONSUMER_PID 2>/dev/null
```

## Verify

### Broker Health Check

```bash
# Check broker is accepting connections
bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092

# Verify broker metadata
bin/kafka-metadata.sh --snapshot /tmp/kraft-combined-logs/__cluster_metadata-0/00000000000000000000.log

# Quick connectivity test with kafka-verifiable-producer
bin/kafka-verifiable-producer.sh --bootstrap-server localhost:9092 --topic test-topic --max-messages 3
```

### Topic Operations

```bash
# List all topics
bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Describe all topics
bin/kafka-topics.sh --bootstrap-server localhost:9092 --describe

# Check consumer groups
bin/kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list
```

### JMX Monitoring (Optional)

Enable JMX for monitoring:

```bash
# Start with JMX enabled
JMX_PORT=9999 bin/kafka-server-start.sh -daemon config/kraft/server.properties

# Connect with jconsole or other JMX client
jconsole &
```

## Rollback

### Stop Kafka

```bash
# Stop the broker
bin/kafka-server-stop.sh

# Force stop if needed
pkill -f kafka.Kafka

# Verify process stopped
ps aux | grep kafka
```

### Clean Up Data and Logs

```bash
# Stop Kafka first
bin/kafka-server-stop.sh

# Remove data and logs (WARNING: destroys all data)
rm -rf /tmp/kafka-logs
rm -rf /tmp/kraft-combined-logs

# Remove downloaded Kafka (optional)
cd ~
rm -rf ~/kafka/kafka_2.13-*
```

### Reset KRaft Storage

If you need to start fresh:

```bash
# Stop Kafka
bin/kafka-server-stop.sh

# Remove storage directories (check your config for paths)
rm -rf /tmp/kafka-logs /tmp/kraft-combined-logs

# Reformat storage
KAFKA_CLUSTER_ID=$(bin/kafka-storage.sh random-uuid)
bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c config/kraft/server.properties

# Restart Kafka
bin/kafka-server-start.sh -daemon config/kraft/server.properties
```

## Common Errors

### "Kafka server failed to start"

Check Java version:
```bash
java -version
# Must be Java 11 or higher
```

Check logs:
```bash
tail -f logs/server.log
```

### "Connection refused to localhost:9092"

Verify broker is running:
```bash
ps aux | grep kafka
```

Check port is listening:
```bash
netstat -tlnp | grep 9092
# or
ss -tlnp | grep 9092
```

### "Topic creation failed"

Check broker is reachable:
```bash
bin/kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

### "Out of memory error"

Increase heap size:
```bash
export KAFKA_HEAP_OPTS="-Xmx2G -Xms2G"
bin/kafka-server-start.sh config/kraft/server.properties
```

### "Disk space low"

Check disk usage:
```bash
df -h
```

Reduce log retention in server.properties:
```bash
log.retention.hours=1
log.retention.check.interval.ms=60000
```

### "Port 9092 already in use"

Find and kill the process:
```bash
lsof -i :9092
# or
ss -tlnp | grep 9092
kill <PID>
```

## References

- Apache Kafka official documentation: https://kafka.apache.org/documentation/ (verified: 2026-03-12)
- Kafka quickstart guide: https://kafka.apache.org/quickstart (verified: 2026-03-12)
- KRaft mode overview: https://kafka.apache.org/documentation/#kraft (verified: 2026-03-12)
- Kafka download archives: https://archive.apache.org/dist/kafka/ (verified: 2026-03-12)
