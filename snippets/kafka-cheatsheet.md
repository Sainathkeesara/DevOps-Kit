# Kafka CLI Cheatsheet

## Environment Setup

```bash
# Set default bootstrap server
export KAFKA_BOOTSTRAP_SERVER=localhost:9092

# Or pass to each command
--bootstrap-server kafka:9092
```

## Topics

### List Topics
```bash
# Basic list
kafka-topics.sh --list

# Detailed description
kafka-topics.sh --describe --topic my-topic

# All topics detailed
kafka-topics.sh --describe
```

### Create Topic
```bash
kafka-topics.sh --create \
  --topic my-topic \
  --partitions 6 \
  --replication-factor 3
```

### Delete Topic
```bash
kafka-topics.sh --delete --topic my-topic
```

### Alter Topic
```bash
# Add partitions
kafka-topics.sh --alter --topic my-topic --partitions 12

# Change config
kafka-topics.sh --alter --topic my-topic \
  --config retention.ms=86400000

# Remove config
kafka-topics.sh --alter --topic my-topic \
  --delete-config retention.ms
```

## Consumer Groups

### List Groups
```bash
kafka-consumer-groups.sh --list
```

### Describe Group
```bash
kafka-consumer-groups.sh --describe --group my-group
```

### Reset Offsets
```bash
# Reset to earliest
kafka-consumer-groups.sh --reset-offsets \
  --group my-group \
  --topic my-topic \
  --to-earliest \
  --execute

# Reset to latest
kafka-consumer-groups.sh --reset-offsets \
  --group my-group \
  --topic my-topic \
  --to-latest \
  --execute

# Reset by offset
kafka-consumer-groups.sh --reset-offsets \
  --group my-group \
  --topic my-topic:0 \
  --to-offset 1000 \
  --execute
```

### Delete Group
```bash
kafka-consumer-groups.sh --delete --group my-group
```

## Producing Messages

### Basic Producer
```bash
kafka-console-producer.sh \
  --topic my-topic \
  --property "parse.key=true" \
  --property "key.separator=,"
```

### Producer with Headers
```bash
kafka-console-producer.sh \
  --topic my-topic \
  --property "parse.headers=true" \
  --property "headers.separator=,"
```

## Consuming Messages

### Basic Consumer
```bash
# From beginning
kafka-console-consumer.sh \
  --topic my-topic \
  --from-beginning

# Latest only
kafka-console-consumer.sh --topic my-topic

# Specific partition
kafka-console-consumer.sh \
  --topic my-topic \
  --partition 0 \
  --offset 100
```

### Consumer with Deserializer
```bash
kafka-console-consumer.sh \
  --topic my-topic \
  --from-beginning \
  --key-deserializer org.apache.kafka.common.serialization.StringDeserializer \
  --value-deserializer org.apache.kafka.common.serialization.StringDeserializer
```

## Cluster Operations

### Broker API Versions
```bash
kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

### Reassign Partitions
```bash
# Generate reassignment JSON
kafka-reassign-partitions.sh \
  --bootstrap-server localhost:9092 \
  --topics-to-move-json-file topics.json \
  --broker-list "0,1,2" \
  --generate

# Execute reassignment
kafka-reassign-partitions.sh \
  --bootstrap-server localhost:9092 \
  --reassignment-json-file reassign.json \
  --execute

# Verify progress
kafka-reassign-partitions.sh \
  --bootstrap-server localhost:9092 \
  --reassignment-json-file reassign.json \
  --verify
```

### Preferred Replica Election
```bash
kafka-leader-election.sh \
  --bootstrap-server localhost:9092 \
  --election-type preferred \
  --topic my-topic \
  --partition 0
```

## Configuration

### Dynamic Configs (Broker)
```bash
# List configs
kafka-configs.sh --bootstrap-server localhost:9092 \
  --entity-type brokers \
  --entity-default --describe

# Set config
kafka-configs.sh --bootstrap-server localhost:9092 \
  --entity-type brokers \
  --entity-default \
  --alter --add-config log.retention.hours=168
```

### Topic Configs
```bash
# Describe
kafka-configs.sh --bootstrap-server localhost:9092 \
  --entity-type topics --entity-name my-topic --describe

# Set
kafka-configs.sh --bootstrap-server localhost:9092 \
  --entity-type topics --entity-name my-topic \
  --alter --add-config retention.ms=3600000
```

## ACLs (Security)

### List ACLs
```bash
kafka-acls.sh --bootstrap-server localhost:9092 --list
```

### Grant Permissions
```bash
# Producer access
kafka-acls.sh --bootstrap-server localhost:9092 \
  --add --allow-principal User:app-producer \
  --operation Write --topic my-topic

# Consumer access
kafka-acls.sh --bootstrap-server localhost:9092 \
  --add --allow-principal User:app-consumer \
  --operation Read --topic my-topic \
  --group my-group
```

## Log Operations

### Dump Log Segments
```bash
kafka-dump-log.sh --files /var/lib/kafka-logs/my-topic-0/00000000000000000000.log
```

### Verify Log Segments
```bash
kafka-run-class.sh kafka.tools.DumpLogSegments \
  --files /var/lib/kafka-logs/my-topic-0/*.log \
  --verify-index-only
```

## Performance Testing

### Producer Performance
```bash
kafka-producer-perf-test.sh \
  --topic test-topic \
  --num-records 1000000 \
  --record-size 1024 \
  --throughput -1 \
  --producer-props bootstrap.servers=localhost:9092
```

### Consumer Performance
```bash
kafka-consumer-perf-test.sh \
  --topic test-topic \
  --messages 1000000 \
  --bootstrap-server localhost:9092
```

## Common Configs Reference

| Config | Description | Default |
|--------|-------------|---------|
| `retention.ms` | Log retention time | 7 days |
| `retention.bytes` | Log retention size | unlimited |
| `cleanup.policy` | delete/compact | delete |
| `compression.type` | producer compression | producer |
| `min.insync.replicas` | Min replicas for acks=all | 1 |
| `max.message.bytes` | Max message size | 1MB |

## Troubleshooting Commands

```bash
# Check under-replicated partitions
kafka-topics.sh --describe | grep -E "Topic:|Leader: none|Isr:"

# Find partitions without leader
kafka-topics.sh --describe | grep "Leader: none"

# Consumer lag by group
kafka-consumer-groups.sh --describe --group my-group | awk '{print $6}' | grep -v LAG
```
