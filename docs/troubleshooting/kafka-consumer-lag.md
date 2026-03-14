# Troubleshooting Kafka Consumer Lag and Rebalancing

## Purpose

Diagnose and resolve consumer lag issues and rebalancing problems in Apache Kafka. High consumer lag indicates that consumers are falling behind producers, causing delays in message processing.

## When to use

- Consumer lag is continuously increasing
- Messages are taking longer to process than expected
- Consumer group rebalances are happening frequently
- Consumer group shows `REBALANCING` status frequently
- Throughput is lower than expected in consumer applications

## Prerequisites

- `kafka-consumer-groups.sh` from Kafka distribution
- Network connectivity to Kafka bootstrap servers
- Appropriate ACLs to describe consumer groups
- Optional: `kafka-topics.sh`, `kafka-broker-api-versions.sh` for deeper diagnostics

## Steps

### 1. Identify affected consumer groups

```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --list
```

Note the group names. Then describe each group:

```bash
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group <group-name>
```

Look for:
- High `LAG` values (difference between `CURRENT-OFFSET` and `LOG-END-OFFSET`)
- Partitions assigned unevenly across consumers

### 2. Analyze lag metrics

```bash
# Check lag for all groups
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --all-groups | awk '$6 > 1000 {print}'
```

Identify patterns:
- Single consumer vs. all partitions lagging
- Specific topics with high lag
- Time-based lag trends

### 3. Identify rebalancing issues

```bash
# Describe group multiple times to see state changes
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group <group-name>

# Check for REBALANCING state in output
# Look for assignment strategy changes
```

### 4. Common causes and fixes

#### a. Insufficient consumers

If lag is high and only one consumer exists:

```bash
# Add more consumers to the group
# Kafka automatically partitions across consumers
# Ensure partition count > consumer count for parallelism
```

Check partition count:

```bash
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --topic <topic-name>
```

#### b. Consumer processing time too slow

If consumers are slow to process messages:

```bash
# Increase consumer batch size
# consumer.max.poll.records=500

# Increase fetch size
# fetch.max.bytes=52428800

# Reduce poll timeout
# max.poll.interval.ms=300000
```

#### c. Consumer group rebalancing storms

Frequent rebalances cause throughput drops:

```bash
# Add static membership to prevent rebalances on restart
group.instance.id=consumer-1

# Increase session timeout to reduce rebalances
session.timeout.ms=45000

# Increase heartbeat interval
heartbeat.interval.ms=10000
```

#### d. Unbalanced partition assignment

If partitions are unevenly distributed:

```bash
# Check partition distribution
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group <group-name> | grep -E "^[[:space:]]"

# Consider custom partitioner for key-based topics
# Use round-robin for keys with skewed distribution
```

#### e. Broker or network issues

Check broker health:

```bash
kafka-broker-api-versions.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER

# Check for under-replicated partitions
kafka-topics.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --topic <topic-name> | grep -i under
```

Fix under-replicated partitions:

```bash
# Reassign replicas
# See partition reassignment tool
```

#### f. Sticky partitioner issues

If same partitions are always lagging:

```bash
# Check if certain keys are causing hotspots
# Review producer partitioner settings

# Consider changing partitioner
# partitioner.adaptive.partitioning.enable=true
# partitioner.availability.timeout.ms=0
```

### 5. Diagnose rebalancing root causes

#### Check consumer heartbeats

```bash
# Monitor consumer metrics
# consumer_lag_seconds should be low
# heartbeat-response-time-max-ms should be stable
```

#### Review consumer logs

Look for:
- `MemberId` changes
- `Rebalance` events
- `SyncGroup` failures

#### Adjust rebalancing parameters

```bash
# Reduce join group timeout
# If consumers are slow to join
# join.group.timeout.ms=60000

# Increase max poll interval for slow processing
# max.poll.interval.ms=600000

# Configure cooperative rebalancing (Kafka 2.4+)
# partition.assignment.strategy=cooperative-sticky
```

### 6. Monitor ongoing lag

```bash
# Continuous monitoring
watch -n 5 'kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group <group-name>'
```

Or use Prometheus metrics:
- `kafka_consumer_group_lag_seconds`
- `kafka_consumer_group_member_count`

## Verify

After applying fixes:

```bash
# Verify lag is decreasing
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --describe --group <group-name>

# Check LAG column - should approach 0 for healthy consumers

# Verify no ongoing rebalances
# Run describe multiple times - STATE should be STABLE
```

Expected output:
```
GROUP                   TOPIC           PARTITION  CURRENT-OFFSET  LOG-END-OFFSET  LAG     CONSUMER                                         HOST                   
my-group               my-topic        0          1000            1000            0       consumer-1-abc123/host1                          /192.168.1.1
```

## Rollback

If issues started after configuration changes:

```bash
# Reset consumer group to latest offset
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --group <group-name> \
  --reset-offsets --topic <topic-name> \
  --to-latest --execute

# Or reset to specific timestamp
kafka-consumer-groups.sh --bootstrap-server $KAFKA_BOOTSTRAP_SERVER \
  --group <group-name> \
  --reset-offsets --topic <topic-name> \
  --to-datetime "2024-01-01T00:00:00.000" \
  --execute
```

## Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| `GROUP_COORDINATOR_NOT_AVAILABLE` | Coordinator broker down | Check broker health and network |
| `NOT_COORDINATOR_GROUP` | Wrong coordinator | Retry with fresh describe |
| `MEMBER_ID_REQUIRED` | New consumer needs ID | Ensure group.instance.id is set |
| `INCONSISTENT_GROUP_PROTOCOL` | Conflicting assignment strategies | Align partition.assignment.strategy |
| `UNKNOWN_MEMBER_ID` | Member was removed | Consumer needs to rejoin |
| `REBALANCE_IN_PROGRESS` | Group rebalancing | Wait for completion, check for issues |
| `IllegalStateException` | Consumer not subscribed | Call subscribe() before poll() |
| `FencedInstanceIdException` | Another consumer with same ID | Use unique group.instance.id |

## References

- Apache Kafka Consumer Configuration — https://kafka.apache.org/documentation/#consumerconfigs (verified: 2026-03-14)
- Kafka Consumer Group Protocol — https://kafka.apache.org/documentation/#impl_consumergroup (verified: 2026-03-14)
- Monitoring Kafka Consumer Lag — https://kafka.apache.org/documentation/#monitoring (verified: 2026-03-14)
