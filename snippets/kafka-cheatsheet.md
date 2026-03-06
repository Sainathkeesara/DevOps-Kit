# Kafka Cheatsheet

## Environment

```bash
export KAFKA_BOOTSTRAP_SERVER="localhost:9092"
export KAFKA_HOME="/opt/kafka"
export PATH="$PATH:$KAFKA_HOME/bin"
```

## Topics

### List Topics
```bash
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER --list
```

### Create Topic
```bash
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --create --topic events \
  --partitions 6 --replication-factor 3
```

### Describe Topic
```bash
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --topic events
```

### Delete Topic
```bash
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --delete --topic events
```

### Alter Partitions
```bash
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --alter --topic events --partitions 12
```

### Topic Configs
```bash
# Set retention
kafka-configs.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --entity-type topics --entity-name events \
  --alter --add-config retention.ms=604800000

# Common configs
min.insync.replicas=2
compression.type=snappy
cleanup.policy=delete|compact
retention.ms=604800000  # 7 days
max.message.bytes=1048576
```

## Consumer Groups

### List Groups
```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER --list
```

### Describe Group
```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group order-processor
```

### Reset Offsets (Dry Run)
```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --reset-offsets --group order-processor --topic orders --to-earliest --dry-run
```

### Reset Offsets (Execute)
```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --reset-offsets --group order-processor --topic orders --to-earliest --execute
```

### Delete Group
```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --delete --group order-processor
```

## Producing Messages

### Console Producer
```bash
kafka-console-producer.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --topic events
```

### With Key
```bash
kafka-console-producer.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --topic events \
  --property parse.key=true --property key.separator=,
# Then type: key,value
```

### Producer Properties
```bash
kafka-console-producer.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --topic events \
  --producer-property acks=all \
  --producer-property retries=3
```

## Consuming Messages

### Basic Consume
```bash
kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --topic events
```

### From Beginning
```bash
kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --topic events --from-beginning
```

### Max Messages
```bash
kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --topic events --max-messages 100
```

### Consumer Group
```bash
kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --topic events --group my-group
```

### Show Key and Value
```bash
kafka-console-consumer.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --topic events --from-beginning \
  --property print.key=true --property key.separator=" => "
```

## Cluster Health

### Broker API Versions
```bash
kafka-broker-api-versions.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER
```

### Metadata Quorum (KRaft)
```bash
kafka-metadata-quorum.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER --describe --status
```

### Log Directories
```bash
kafka-log-dirs.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --broker-list 1,2,3
```

### Replication Verification
```bash
kafka-replica-verification.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER
```

## ACL Management

### List ACLs
```bash
kafka-acls.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER --list
```

### Add Read ACL
```bash
kafka-acls.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --add --allow-principal User:app-user \
  --operation Read --topic events
```

### Add Write ACL
```bash
kafka-acls.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --add --allow-principal User:producer \
  --host "10.0.0.*" \
  --operation Write --topic events
```

### Add Consumer Group ACL
```bash
kafka-acls.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --add --allow-principal User:app-user \
  --operation Read --group app-consumer
```

### Remove ACL
```bash
kafka-acls.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --remove --allow-principal User:old-user \
  --operation Read --topic events
```

### ACL Operations
- `Read` - Read from topic, consume from group
- `Write` - Write to topic
- `Create` - Create topic
- `Delete` - Delete topic
- `Alter` - Modify topic config/partitions
- `Describe` - View topic metadata
- `ClusterAction` - Cluster-level operations
- `All` - All operations

### ACL Pattern Types
- `LITERAL` - Exact name match
- `PREFIXED` - Prefix match
- `WILDCARD` - Wildcard match

## Monitoring

### Consumer Lag Check
```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group order-processor
```

### Calculate Total Lag
```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group <group> | awk '{print $0; lag+=$5} END {print "\nTotal Lag:", lag}'
```

### Consumer Lag with State
```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group <group> --members --verbose
```

### Throughput Test (Producer)
```bash
kafka-producer-perf-test.sh \
  --topic events \
  --num-records 100000 \
  --record-size 1000 \
  --throughput 1000 \
  --producer-props bootstrap.servers=$KAFKA_BOOTSTRAP_SERVER
```

### Throughput Test (Consumer)
```bash
kafka-consumer-perf-test.sh \
  --topic events \
  --messages 100000 \
  --bootstrap-server $KAFKA_BOOTSTRAP_SERVER
```

### Partition Distribution
```bash
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --topic events | grep -E "Leader|Replicas"
```

### Under-Replicated Partitions
```bash
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --under-replicated-partitions
```

### Offline Partitions
```bash
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --unavailable-partitions
```

## Partition Reassignment

### Generate Reassignment Plan
```bash
kafka-reassign-partitions.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --generate \
  --topics-to-move-json-string '{"topics": ["events","orders"]}' \
  --broker-list "1,2,3"
```

### Execute Reassignment
```bash
kafka-reassign-partitions.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --execute \
  --reassignment-json-file reassignment.json \
  --throttle 52428800
```

### Verify Reassignment
```bash
kafka-reassign-partitions.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --verify \
  --reassignment-json-file reassignment.json
```

### Cancel Reassignment
```bash
kafka-reassign-partitions.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --cancel \
  --reassignment-json-file reassignment.json
```

### Throttle Calculation
```bash
# 50 MB/s = 52428800 bytes/s
# 100 MB/s = 104857600 bytes/s
```

## Performance Testing

### Producer Perf Test
```bash
kafka-producer-perf-test.sh \
  --topic events \
  --num-records 100000 \
  --record-size 1000 \
  --throughput 1000 \
  --producer-props bootstrap.servers=$KAFKA_BOOTSTRAP_SERVER
```

### Consumer Perf Test
```bash
kafka-consumer-perf-test.sh \
  --topic events \
  --messages 100000 \
  --bootstrap-server $KAFKA_BOOTSTRAP_SERVER
```

## Configuration Files

### Client Properties (client.properties)
```properties
bootstrap.servers=localhost:9092
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required \
  username="user" \
  password="pass";
ssl.truststore.location=/path/to/truststore.jks
ssl.truststore.password=password
```

## kcat (kafkacat) Quick Reference

### Install
```bash
# macOS
brew install kcat

# Ubuntu/Debian
apt-get install kafkacat
```

### Produce
```bash
echo "message" | kcat -b localhost:9092 -t events -P
```

### Consume
```bash
kcat -b localhost:9092 -t events -C
kcat -b localhost:9092 -t events -C -o beginning
kcat -b localhost:9092 -t events -C -o end
```

### List Topics
```bash
kcat -b localhost:9092 -L
```

## Kafka 4.0+ KRaft Mode (No ZooKeeper)

### Format Storage
```bash
kafka-storage.sh format -t $(kafka-storage.sh random-uuid) -c config/kraft/server.properties
```

### Start Server
```bash
kafka-server-start.sh config/kraft/server.properties
```

## Troubleshooting

### Check Consumer Lag
```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group <group> | awk '{print $0; lag+=$5} END {print "\nTotal Lag:", lag}'
```

### Find Largest Topics
```bash
kafka-log-dirs.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe | grep -E 'topic|size'
```

### Dump Log Segment
```bash
kafka-dump-log.sh --files /path/to/segment.log --print-data-log
```

## Resources

- https://kafka.apache.org/documentation/
- https://docs.confluent.io/kafka/operations-tools/index.html
- https://github.com/edenhill/kcat
