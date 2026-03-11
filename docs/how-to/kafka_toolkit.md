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

#### check-lag.sh

Check consumer group lag with threshold-based alerts.

```bash
# Check all consumer groups
./scripts/bash/kafka_toolkit/consumers/check-lag.sh

# Check specific group
./scripts/bash/kafka_toolkit/consumers/check-lag.sh -g order-processor

# Lower threshold for alert
./scripts/bash/kafka_toolkit/consumers/check-lag.sh -T 5000

# JSON output for monitoring
./scripts/bash/kafka_toolkit/consumers/check-lag.sh -f json -g processor-group
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

### ACL Management

#### manage-acls.sh

Manage Kafka ACLs: list, add, and remove access control rules.

```bash
# List all ACLs
./scripts/bash/kafka_toolkit/acl/manage-acls.sh --list

# Allow user to read from a topic
./scripts/bash/kafka_toolkit/acl/manage-acls.sh \
  --add \
  --principal User:app-user \
  --host "*" \
  --operation Read \
  --resource-type Topic \
  --resource-name events \
  -e

# Allow user to write to a topic
./scripts/bash/kafka_toolkit/acl/manage-acls.sh \
  --add \
  --principal User:producer \
  --host "10.0.0.*" \
  --operation Write \
  --resource-type Topic \
  --resource-name events \
  -e

# Allow consumer group access
./scripts/bash/kafka_toolkit/acl/manage-acls.sh \
  --add \
  --principal User:app-user \
  --host "*" \
  --operation Read \
  --resource-type Group \
  --resource-name app-consumer \
  -e

# Remove an ACL (dry-run first)
./scripts/bash/kafka_toolkit/acl/manage-acls.sh \
  --remove \
  --principal User:old-user \
  --operation Read \
  --resource-type Topic \
  --resource-name events
```

### Monitoring

#### consumer-lag.sh

Monitor Kafka consumer lag across groups and topics with alerting.

```bash
# Check all consumer groups
./scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh

# Check specific group
./scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh -g order-processor

# Check specific topic across all groups
./scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh -t events

# Alert on lower threshold
./scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh -T 5000

# JSON output for automation
./scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh -f json

# Sort by group name
./scripts/bash/kafka_toolkit/monitoring/consumer-lag.sh -s group
```

#### throughput-check.sh

Monitor Kafka topic throughput and message rates.

```bash
# Check throughput for all topics (sample)
./scripts/bash/kafka_toolkit/monitoring/throughput-check.sh -d 5

# Check specific topic
./scripts/bash/kafka_toolkit/monitoring/throughput-check.sh -t events -d 10

# Longer sampling for accurate baseline
./scripts/bash/kafka_toolkit/monitoring/throughput-check.sh \
  -t high-volume-topic -d 30 -i 5
```

### Partition Reassignment

#### partition-reassign.sh

Generate, execute, and verify Kafka partition reassignment plans.

```bash
# Generate plan for specific topics
./scripts/bash/kafka_toolkit/partitions/partition-reassign.sh \
  --generate -t events,orders -B 1,2,3

# Generate plan for all topics with throttle
./scripts/bash/kafka_toolkit/partitions/partition-reassign.sh \
  --generate -B 4,5,6 -T 50

# Execute reassignment from file
./scripts/bash/kafka_toolkit/partitions/partition-reassign.sh \
  --execute -f reassignment.json

# Verify reassignment progress
./scripts/bash/kafka_toolkit/partitions/partition-reassign.sh \
  --verify -f reassignment.json

# Cancel ongoing reassignment
./scripts/bash/kafka_toolkit/partitions/partition-reassign.sh \
  --cancel -f reassignment.json

# Dry-run first (recommended)
./scripts/bash/kafka_toolkit/partitions/partition-reassign.sh \
  --generate -t events -B 1,2,3
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
| `ACL operation not permitted` | Missing ACL permissions | Contact admin to grant ACL access |
| `Reassignment already in progress` | Concurrent reassignment | Wait for current reassignment to complete |
| `Throttle not specified` | Large reassignment without throttle | Add `--throttle` to limit replication I/O |

## References

- https://kafka.apache.org/documentation/
- https://kafka.apache.org/25/operations/basic-kafka-operations/
- https://docs.confluent.io/kafka/operations-tools/index.html
- https://github.com/edenhill/kcat (kafkacat tool)
