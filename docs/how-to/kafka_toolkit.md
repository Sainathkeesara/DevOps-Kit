# Kafka Toolkit

## Purpose

The kafka_toolkit provides safe, opinionated helper scripts for common Apache Kafka operations. These wrappers simplify topic management, consumer monitoring, and diagnostic tasks.

## When to use

Use kafka_toolkit scripts when you need to:

- List topics and inspect partition/replica distribution
- Check consumer group lag and offsets
- Create topics with safe defaults and validation
- Test message production and consumption
- Get detailed topic configuration and status

Do not use these for production-critical automation without testing in non-production first. For CI/CD pipelines, review dry-run behavior.

## Prerequisites

- Kafka client tools (`kafka-topics.sh`, `kafka-consumer-groups.sh`, etc.) in PATH
- Connectivity to a Kafka broker (local or remote)
- Appropriate permissions (admin for topic creation, read for diagnostics)
- Environment variable `KAFKA_BOOTSTRAP_SERVER` set, or use `--bootstrap-server` flag

## Installation

No installation required. Clone the DevOps-Kit repository and use scripts directly:

```bash
git clone <repo> devops-kit
cd devops-kit
chmod +x scripts/bash/kafka_toolkit/**/*.sh
```

## Tools

### list-topics.sh

List Kafka topics with optional detailed information.

```bash
./scripts/bash/kafka_toolkit/topics/list-topics.sh [--detailed] [--under-replicated] [--bootstrap-server <host:port>]
```

**Options:**
- `--detailed` - Show partition count, replication factor, and configs
- `--under-replicated` - Show only topics with under-replicated partitions
- `--bootstrap-server` - Kafka broker address (default: localhost:9092 or $KAFKA_BOOTSTRAP_SERVER)

**Examples:**
```bash
# Basic list
./list-topics.sh

# Detailed view
./list-topics.sh --detailed

# Find problems
./list-topics.sh --under-replicated
```

**Expected behavior:**
- Lists topics alphabetically
- Detailed mode shows partition and replica counts
- Under-replicated filter helps identify availability issues

---

### describe-topic.sh

Get comprehensive details about a specific topic.

```bash
./scripts/bash/kafka_toolkit/topics/describe-topic.sh <topic-name> [--json] [--bootstrap-server <host:port>]
```

**Arguments:**
- `<topic-name>` - Name of the topic to describe

**Options:**
- `--json` - Output in JSON-like format
- `--bootstrap-server` - Kafka broker address

**Example:**
```bash
./describe-topic.sh my-topic
./describe-topic.sh my-topic --json
```

**Output includes:**
- Topic summary (partitions, replication factor)
- Per-partition details (leader, replicas, ISR, offline replicas)
- Custom configurations

---

### topic-create.sh

Create a Kafka topic with validation and safe defaults.

```bash
./scripts/bash/kafka_toolkit/topics/topic-create.sh <topic-name> [--partitions <n>] [--replication-factor <n>] [--dry-run]
```

**Arguments:**
- `<topic-name>` - Name for the new topic

**Options:**
- `--partitions` - Number of partitions (default: 3)
- `--replication-factor` - Replication factor (default: 1)
- `--dry-run` - Preview without creating
- `--bootstrap-server` - Kafka broker address

**Validation:**
- Topic name must be 249 characters or less
- Only alphanumeric characters, dots, underscores, and hyphens allowed
- Checks if topic already exists
- Adjusts replication factor if exceeding broker count

**Example:**
```bash
./topic-create.sh events-topic --partitions 6 --replication-factor 3
./topic-create.sh test-topic --dry-run
```

**Rollback:**
Delete the topic if needed:
```bash
kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic <topic-name>
```

---

### consumer-lag-check.sh

Check consumer group lag and offset information.

```bash
./scripts/bash/kafka_toolkit/consumers/consumer-lag-check.sh [--group <group-id>] [--all-groups] [--lag-threshold <n>]
```

**Options:**
- `--group` - Specific consumer group to check
- `--all-groups` - Check all consumer groups
- `--lag-threshold` - Warn if lag exceeds this value
- `--bootstrap-server` - Kafka broker address

**Examples:**
```bash
# Check all groups
./consumer-lag-check.sh --all-groups

# Check specific group with threshold
./consumer-lag-check.sh --group order-processor --lag-threshold 10000
```

**Output includes:**
- Current offset per partition
- Log end offset
- Consumer lag (difference)
- Consumer ID and host

---

### test-produce-consume.sh

Verify topic connectivity by producing and consuming test messages.

```bash
./scripts/bash/kafka_toolkit/diagnostics/test-produce-consume.sh <topic-name> [--messages <n>] [--cleanup]
```

**Arguments:**
- `<topic-name>` - Topic to test (created if doesn't exist)

**Options:**
- `--messages` - Number of test messages (default: 10)
- `--cleanup` - Delete topic after test
- `--timeout` - Consumer timeout in seconds (default: 30)

**Example:**
```bash
# Quick test with cleanup
./test-produce-consume.sh test-topic --cleanup

# Extended test
./test-produce-consume.sh my-topic --messages 100
```

**Expected behavior:**
- Creates topic if missing (1 partition, RF 1)
- Produces numbered test messages
- Consumes messages and verifies count
- Reports success or partial failure

---

## Verify

Test your Kafka connection:

```bash
# Set bootstrap server
export KAFKA_BOOTSTRAP_SERVER=localhost:9092

# List topics to verify connectivity
./scripts/bash/kafka_toolkit/topics/list-topics.sh

# Test message flow
./scripts/bash/kafka_toolkit/diagnostics/test-produce-consume.sh test-verify --cleanup
```

## Common errors

### kafka-topics.sh: command not found

Install Apache Kafka and ensure `bin/` directory is in PATH:
```bash
export PATH=$PATH:/opt/kafka/bin
```

### Cannot connect to Kafka broker

Verify broker is running and accessible:
```bash
telnet localhost 9092
# or
kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

### Topic already exists

The create script skips creation if topic exists. Use `--dry-run` to preview.

### Not authorized

Topic creation requires admin privileges. Contact cluster administrator for ACLs.

### Consumer group has no active members

Indicates consumers are not running. Start consumer applications before checking lag.

### Under-replicated partitions

Some replicas are not in-sync. Check broker health and network connectivity.

## References

- Apache Kafka Documentation: https://kafka.apache.org/documentation/
- Kafka Operations Guide: https://kafka.apache.org/documentation/#operations
- kafka-topics.sh reference: https://kafka.apache.org/documentation/#basic_ops_add_topic
- kafka-consumer-groups.sh reference: https://kafka.apache.org/documentation/#basic_ops_consumer_group
- Confluent CLI Tools: https://docs.confluent.io/kafka/operations-tools/kafka-tools.html
