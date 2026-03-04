# kafka_toolkit

## Purpose

Safe CLI wrappers and operational helpers for Apache Kafka clusters. Provides topic management, consumer group inspection, message testing, and cluster health checks with dry-run support and guardrails.

## When to use

- Managing Kafka topics in production environments
- Debugging consumer lag and offset issues
- Testing message flow through topics
- Verifying cluster health during incidents
- Automating repetitive Kafka operations

## Prerequisites

- Apache Kafka 2.5+ (3.x+ recommended with KRaft mode)
- `kafka-topics.sh`, `kafka-consumer-groups.sh`, `kafka-console-producer.sh`, `kafka-console-consumer.sh` in PATH
- Network connectivity to Kafka bootstrap servers
- Appropriate ACLs for operations (read-only for basic usage)

## Environment Setup

```bash
# Set default bootstrap server
export KAFKA_BOOTSTRAP_SERVER="kafka.example.com:9092"

# For secured clusters
export KAFKA_COMMAND_CONFIG="/path/to/client.properties"
```

## Scripts

### Topic Management

#### topic-list.sh

List and describe topics with filtering.

```bash
# List all topics
./scripts/bash/kafka_toolkit/topics/topic-list.sh

# List with pattern
./scripts/bash/kafka_toolkit/topics/topic-list.sh -p "prod-*"

# Describe specific topics
./scripts/bash/kafka_toolkit/topics/topic-list.sh -p "events" --describe

# With authentication
./scripts/bash/kafka_toolkit/topics/topic-list.sh -c /etc/kafka/client.properties
```

#### topic-create.sh

Create topics with validation and dry-run.

```bash
# Create basic topic
./scripts/bash/kafka_toolkit/topics/topic-create.sh -t orders -p 6 -r 3

# With configuration
./scripts/bash/kafka_toolkit/topics/topic-create.sh \
  -t events -p 12 -r 3 \
  -c retention.ms=604800000 \
  -c compression.type=snappy

# Dry-run first
./scripts/bash/kafka_toolkit/topics/topic-create.sh \
  -t metrics -p 24 -r 3 -n

# Skip if exists
./scripts/bash/kafka_toolkit/topics/topic-create.sh \
  -t events -p 6 -r 3 --if-not-exists
```

### Consumer Group Management

#### consumer-groups.sh

List, describe, and reset consumer group offsets.

```bash
# List all consumer groups
./scripts/bash/kafka_toolkit/consumers/consumer-groups.sh --list

# Describe group
./scripts/bash/kafka_toolkit/consumers/consumer-groups.sh \
  --describe --group order-processor

# Reset offsets (dry-run by default)
./scripts/bash/kafka_toolkit/consumers/consumer-groups.sh \
  --reset-offsets --group order-processor \
  --topic orders --to-earliest

# Execute reset
./scripts/bash/kafka_toolkit/consumers/consumer-groups.sh \
  --reset-offsets --group order-processor \
  --topic orders --to-earliest --execute

# Reset all topics in group to latest
./scripts/bash/kafka_toolkit/consumers/consumer-groups.sh \
  --reset-offsets --group processor \
  --all-topics --to-latest --execute
```

### Messaging

#### produce-message.sh

Send test messages to topics.

```bash
# Single message
./scripts/bash/kafka_toolkit/messaging/produce-message.sh \
  -t events -m "test message"

# With key
./scripts/bash/kafka_toolkit/messaging/produce-message.sh \
  -t events -k "user-123" -m "login event"

# From file
./scripts/bash/kafka_toolkit/messaging/produce-message.sh \
  -t events -f messages.txt

# From stdin
echo "message" | ./scripts/bash/kafka_toolkit/messaging/produce-message.sh \
  -t events --stdin
```

#### consume-message.sh

Consume messages with safety limits.

```bash
# Consume 10 messages
./scripts/bash/kafka_toolkit/messaging/consume-message.sh \
  -t events -m 10

# From beginning, max 100 messages, 60s timeout
./scripts/bash/kafka_toolkit/messaging/consume-message.sh \
  -t events --from-beginning -m 100 -T 60

# With specific group (for offset tracking)
./scripts/bash/kafka_toolkit/messaging/consume-message.sh \
  -t events -g debug-group -f -m 5
```

### Cluster Administration

#### cluster-health.sh

Verify cluster health and broker status.

```bash
# Basic health check
./scripts/bash/kafka_toolkit/admin/cluster-health.sh

# With timeout
./scripts/bash/kafka_toolkit/admin/cluster-health.sh \
  -b kafka.example.com:9092 -t 5

# Verbose output
./scripts/bash/kafka_toolkit/admin/cluster-health.sh -v
```

## Verify

Verify scripts are executable:

```bash
# Make scripts executable
chmod +x scripts/bash/kafka_toolkit/*/*.sh

# Test topic listing
./scripts/bash/kafka_toolkit/topics/topic-list.sh -v

# Test cluster health
./scripts/bash/kafka_toolkit/admin/cluster-health.sh
```

## Rollback

### Topic Creation Rollback

```bash
# Delete topic if creation was wrong
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --delete --topic <topic-name>
```

### Offset Reset Rollback

```bash
# Before resetting, note current offsets
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group <group>

# Reset back to previous position using --to-offset
./scripts/bash/kafka_toolkit/consumers/consumer-groups.sh \
  --reset-offsets --group <group> --topic <topic> \
  --to-offset <previous-offset> --execute
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Connection refused` | Broker down or wrong address | Verify bootstrap server and network |
| `Topic already exists` | Duplicate create attempt | Use `--if-not-exists` flag |
| `Not authorized` | ACL restriction | Check client credentials and permissions |
| `Unknown topic` | Topic does not exist | Create topic first or check name |
| `Consumer group still active` | Members connected | Stop consumers before offset reset |
| `No brokers available` | All brokers down | Check cluster health, network connectivity |
| `Leader not available` | Partition leader election | Wait for election or check broker logs |

## References

- https://kafka.apache.org/documentation/
- https://kafka.apache.org/25/operations/basic-kafka-operations/
- https://docs.confluent.io/kafka/operations-tools/index.html
- https://github.com/edenhill/kcat (kafkacat tool)
