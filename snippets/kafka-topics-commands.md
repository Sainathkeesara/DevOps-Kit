# Kafka Topics CLI One-Liners Reference

## Purpose

This snippet provides common Apache Kafka CLI one-liners for topic management, partition operations, consumer group management, and troubleshooting.

## When to use

- Creating, listing, and managing Kafka topics
- Checking consumer group offsets
- Verifying topic health and configuration
- Debugging Kafka connectivity issues

## Prerequisites

- Kafka CLI tools installed (`kafka-topics.sh`, `kafka-consumer-groups.sh`)
- ZooKeeper or KRaft configuration
- Network access to Kafka brokers

## Topics Management

### List Topics

```bash
# List all topics
kafka-topics.sh --bootstrap-server localhost:9092 --list

# List topics with Describe
kafka-topics.sh --bootstrap-server localhost:9092 --describe

# List topics in specific namespace (Kubernetes)
kafka-topics.sh --bootstrap-server localhost:9092 --list --topic-pattern "^my-namespace\\..*"
```

### Create Topic

```bash
# Create topic with defaults
kafka-topics.sh --bootstrap-server localhost:9092 \
    --create \
    --topic my-topic

# Create topic with partitions and replication
kafka-topics.sh --bootstrap-server localhost:9092 \
    --create \
    --topic my-topic \
    --partitions 3 \
    --replication-factor 1

# Create topic with custom config
kafka-topics.sh --bootstrap-server localhost:9092 \
    --create \
    --topic my-topic \
    --partitions 6 \
    --replication-factor 3 \
    --config cleanup.policy=compact \
    --config retention.ms=604800000
```

### Delete Topic

```bash
# Delete topic
kafka-topics.sh --bootstrap-server localhost:9092 \
    --delete \
    --topic my-topic

# Delete multiple topics
kafka-topics.sh --bootstrap-server localhost:9092 \
    --delete \
    --topic topic-1,topic-2,topic-3
```

### Describe Topic

```bash
# Describe single topic
kafka-topics.sh --bootstrap-server localhost:9092 \
    --describe \
    --topic my-topic

# Describe all topics with under-replicated partitions
kafka-topics.sh --bootstrap-server localhost:9092 \
    --describe \
    --under-replicated-partitions

# Describe all topics with offline partitions
kafka-topics.sh --bootstrap-server localhost:9092 \
    --describe \
    --unavailable-partitions
```

### Update Topic

```bash
# Increase partitions
kafka-topics.sh --bootstrap-server localhost:9092 \
    --alter \
    --topic my-topic \
    --partitions 6

# Update config
kafka-topics.sh --bootstrap-server localhost:9092 \
    --alter \
    --topic my-topic \
    --config retention.ms=3600000

# Remove config
kafka-topics.sh --bootstrap-server localhost:9092 \
    --alter \
    --topic my-topic \
    --delete-config retention.ms
```

## Consumer Groups

### List Groups

```bash
# List all consumer groups
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --list

# List groups with describe
kafka-consumer-groups.sh --bootstrap-server localhost:9092 --describe --all-groups
```

### Group Information

```bash
# Describe consumer group
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --describe \
    --group my-group

# Describe group with members
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --describe \
    --group my-group \
    --members

# Describe group with verbose member info
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --describe \
    --group my-group \
    --members \
    --verbose
```

### Reset Offsets

```bash
# Reset to earliest
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --reset-offsets \
    --group my-group \
    --topic my-topic \
    --to-earliest

# Reset to latest
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --reset-offsets \
    --group my-group \
    --topic my-topic \
    --to-latest

# Reset to specific offset
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --reset-offsets \
    --group my-group \
    --topic my-topic:5 \
    --to-offset 1000

# Shift by offset
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --reset-offsets \
    --group my-group \
    --topic my-topic \
    --shift-by 100

# Dry-run (show what would happen)
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --reset-offsets \
    --group my-group \
    --topic my-topic \
    --to-earliest \
    --dry-run
```

## Producers and Consumers

### Console Producer

```bash
# Produce messages
kafka-console-producer.sh --bootstrap-server localhost:9092 \
    --topic my-topic

# Produce with keys
kafka-console-producer.sh --bootstrap-server localhost:9092 \
    --topic my-topic \
    --property parse.key=true \
    --property key.separator=:

# Produce with compression
kafka-console-producer.sh --bootstrap-server localhost:9092 \
    --topic my-topic \
    --compression-codec gzip
```

### Console Consumer

```bash
# Consume from beginning
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic my-topic \
    --from-beginning

# Consume latest only
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic my-topic

# Consume with consumer group
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic my-topic \
    --group my-group

# Consume with key and timestamp
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic my-topic \
    --property print.timestamp=true \
    --property print.key=true \
    --property print.value=true

# Consume only specific partitions
kafka-console-consumer.sh --bootstrap-server localhost:9092 \
    --topic my-topic \
    --partition 0,1
```

## Configuration

### Broker Configuration

```bash
# Describe broker configs
kafka-configs.sh --bootstrap-server localhost:9092 \
    --describe \
    --entity-type brokers \
    --entity-name 0

# Update broker config
kafka-configs.sh --bootstrap-server localhost:9092 \
    --alter \
    --entity-type brokers \
    --entity-name 0 \
    --add-config log.retention.hours=168
```

### Topic Configuration

```bash
# Describe topic config
kafka-configs.sh --bootstrap-server localhost:9092 \
    --describe \
    --entity-type topics \
    --entity-name my-topic

# Update topic config
kafka-configs.sh --bootstrap-server localhost:9092 \
    --alter \
    --entity-type topics \
    --entity-name my-topic \
    --add-config retention.ms=86400000
```

## Leadership and Replica Distribution

### Preferred Leader Election

```bash
# Trigger preferred replica election
kafka-leader-election.sh --bootstrap-server localhost:9092 \
    --election-type preferred \
    --topic my-topic

# Trigger for all topics
kafka-leader-election.sh --bootstrap-server localhost:9092 \
    --election-type preferred \
    --all-topics
```

### Replica Verification

```bash
# Verify replica distribution
kafka-reassign-partitions.sh --bootstrap-server localhost:9092 \
    --verify \
    --reassignment-json-file reassignment.json

# Generate replica assignment
kafka-reassign-partitions.sh --bootstrap-server localhost:9092 \
    --generate \
    --topics-to-move-json-file topics.json \
    --broker-list 0,1,2
```

## Offsets

### Show Consumer Offsets

```bash
# Get current offset for group
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --group my-group \
    --describe | grep my-topic

# Get lag for all topics
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --group my-group \
    --describe | grep -E "lag|my-topic"
```

### Get End Offsets

```bash
# Get latest offset for partition
kafka-run-class.sh kafka.tools.GetOffsetShell \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --time -1

# Get earliest offset
kafka-run-class.sh kafka.tools.GetOffsetShell \
    --bootstrap-server localhost:9092 \
    --topic my-topic \
    --time -2
```

## Troubleshooting

```bash
# Check consumer group lag
kafka-consumer-groups.sh --bootstrap-server localhost:9092 \
    --group my-group \
    --describe | awk '$4 > 1000 {print "LAG: " $4 " for " $2}'

# Find topics with no leaders
kafka-topics.sh --bootstrap-server localhost:9092 \
    --describe | grep -E "Leader:None"

# Check ISR (In-Sync Replicas)
kafka-topics.sh --bootstrap-server localhost:9092 \
    --describe | grep -E "ISR:\[.*\]"

# Check controller broker
kafka-broker-api-versions.sh --bootstrap-server localhost:9092 | head -1
```

## Verify

After running commands, verify:
- Topics created with correct partition/replication
- Consumer groups showing expected lag
- Producers able to send messages
- Consumers able to receive messages

## Rollback

- Deleted topics: Cannot be recovered without backup
- Offset resets: Can be re-reset to previous values
- Config changes: Can be reverted with --delete-config

## Common Errors

| Error | Solution |
|-------|----------|
| `Topic does not exist` | Create topic first or check spelling |
| `Replication factor not met` | Ensure enough brokers available |
| `Consumer offset commit failed` | Check consumer group is active |
| `Leader not available` | Check broker health and replication |
| `Replica(s) not available` | Check ISR and add replicas |

## References

- [Kafka Topic Commands](https://kafka.apache.org/documentation/#topicops)
- [Kafka Consumer Groups](https://kafka.apache.org/documentation/#consumergroups)
- [Kafka Configuration](https://kafka.apache.org/documentation/#brokerconfigs)
