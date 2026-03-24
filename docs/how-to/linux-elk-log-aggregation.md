# Linux Log Aggregation System with ELK Stack

## Purpose

This guide explains how to set up a comprehensive Linux log aggregation system using the ELK stack (Elasticsearch, Logstash, Kibana) with Filebeat for forwarding. The solution provides centralized logging, real-time search, visualization, and analysis across multiple Linux servers.

## When to Use

Use this log aggregation solution when you need to:

- Centralize logs from multiple Linux servers in a single location
- Search and analyze logs in real-time across your infrastructure
- Create visual dashboards for log monitoring and alerting
- Troubleshoot issues that span multiple servers
- Meet compliance requirements for log retention and audit trails
- Analyze historical log data for capacity planning and trend identification

## Prerequisites

### Required Components
- **Elasticsearch** (v8.x) — distributed search and analytics engine
- **Logstash** (v8.x) — log processing pipeline
- **Kibana** (v8.x) — visualization and dashboarding
- **Filebeat** (v8.x) — lightweight log forwarder

### System Requirements
- **OS**: Ubuntu 20.04/22.04, RHEL 8/9, Debian 11/12
- **RAM**: Minimum 4GB for Elasticsearch (8GB+ recommended for production)
- **CPU**: 2+ cores
- **Disk**: 50GB+ for log storage (depends on retention policy)
- **Privileges**: Root access for installation and service configuration

### Network Requirements
- Port 9200: Elasticsearch REST API
- Port 5601: Kibana web interface
- Port 5044: Logstash Beats input
- Port 9300: Elasticsearch node-to-node communication (if clustering)

## Steps

### Step 1: Prepare the Server

Ensure your system meets the requirements and prepare it for ELK installation:

```bash
# Update system packages
sudo apt-get update && sudo apt-get upgrade -y  # Debian/Ubuntu
# sudo dnf update -y  # RHEL/Rocky

# Install Java (required for Elasticsearch)
sudo apt-get install -y openjdk-17-jdk
# sudo dnf install -y java-17-openjdk  # RHEL/Rocky

# Verify Java installation
java -version

# Createelk user (recommended for production)
sudo useradd -m -s /bin/bash elk
```

### Step 2: Configure Kernel Parameters

Elasticsearch requires specific kernel parameters for optimal performance:

```bash
# Add to /etc/sysctl.conf
sudo tee -a /etc/sysctl.conf <<EOF
vm.max_map_count=262144
fs.file-max=65536
EOF

# Apply immediately
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536

# Add to /etc/security/limits.conf
sudo tee -a /etc/security/limits.conf <<EOF
elk soft nofile 65536
elk hard nofile 65536
elk soft nproc 4096
elk hard nproc 4096
EOF
```

### Step 3: Download and Install ELK Components

Run the automated setup script:

```bash
# Download the setup script
curl -O https://raw.githubusercontent.com/Sainathkeesara/DevOps-Kit/main/scripts/bash/linux_toolkit/logging/elk-setup.sh
chmod +x elk-setup.sh

# Preview installation (dry-run)
sudo ./elk-setup.sh --dry-run

# Run full installation
sudo ./elk-setup.sh --version 8.12.0 --es-heap-size 4g --kibana-port 5601

# Or install specific components only
sudo ./elk-setup.sh --components elasticsearch,kibana
```

### Step 4: Verify Elasticsearch is Running

```bash
# Check Elasticsearch service status
sudo systemctl status elasticsearch

# Test Elasticsearch API
curl -X GET "http://localhost:9200"

# Expected response:
# {
#   "name" : "elk-node-1",
#   "cluster_name" : "elk-cluster",
#   "cluster_uuid" : "xxxxx",
#   "version" : {
#     "number" : "8.12.0",
#     "build_flavor" : "default",
#     "build_type" : "docker",
#     "build_hash" : "xxxxx",
#     "build_date" : "2024-01-01T00:00:00.000000Z",
#     "build_snapshot" : false,
#     "lucene_version" : "9.8.0",
#     "minimum_wire_compatibility_version" : "7.17.0",
#     "minimum_index_compatibility_version" : "7.0.0"
#   },
#   "tagline" : "You Know, for Search"
# }
```

### Step 5: Configure Elasticsearch Security

```bash
# Set the elastic user password (change 'changeme' to a secure password)
curl -X POST -u elastic:changeme "http://localhost:9200/_security/user/elastic/_password" \
  -H 'Content-Type: application/json' \
  -d '{"password":"your_secure_password_here"}'

# Create additional users if needed
curl -X POST -u elastic:your_secure_password_here "http://localhost:9200/_security/user/logstash_writer" \
  -H 'Content-Type: application/json' \
  -d '{
    "password" : "logstash_password",
    "roles" : ["logstash_writer", "kibana_user"]
  }'
```

### Step 6: Verify Kibana is Running

```bash
# Check Kibana service status
sudo systemctl status kibana

# Access Kibana web interface
# Open browser to: http://your-server-ip:5601

# Login with:
# Username: elastic
# Password: your_secure_password_here
```

### Step 7: Configure Filebeat on Client Servers

Install and configure Filebeat to forward logs to Logstash:

```bash
# On each client server, download Filebeat
curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.12.0-linux-x86_64.tar.gz
tar xzf filebeat-8.12.0-linux-x86_64.tar.gz
cd filebeat-8.12.0-linux-x86_64

# Configure Filebeat to send to your Logstash server
sudo cat > filebeat.yml <<EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/syslog
    - /var/log/auth.log
    - /var/log/nginx/*.log
    - /var/log/apache2/*.log
  fields:
    service: system
  fields_under_root: true

- type: log
  enabled: true
  paths:
    - /var/log/**/*.log
  fields:
    service: application
  fields_under_root: true

output.logstash:
  hosts: ["logstash-server.example.com:5044"]
  ssl.enabled: false

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~
EOF

# Start Filebeat
sudo ./filebeat -e &
```

### Step 8: Create Kibana Index Patterns

After logging into Kibana:

1. Navigate to **Stack Management** → **Index Patterns**
2. Click **Create index pattern**
3. Enter pattern: `filebeat-*`
4. Select `@timestamp` as the time field
5. Click **Create index pattern**
6. Repeat for other index patterns (e.g., `logstash-*`, `syslog-*`)

### Step 9: Create Sample Dashboards

Create visualizations in Kibana:

```bash
# Example: Create a simple search for errors
# In Kibana, go to Discover and search:
# message: ERROR AND NOT message: "connection refused"
```

Common visualizations to create:
- **Error Rate Over Time**: Line chart showing errors per minute/hour
- **Top Error Sources**: Pie chart showing which servers generate most errors
- **Log Volume by Service**: Bar chart of logs per service
- **Response Time Percentiles**: Line chart of API response times

### Step 10: Configure Log Retention

```bash
# Create a rollover policy for index management
curl -X PUT -u elastic:your_password "http://localhost:9200/_ilm/policy/logs-policy" \
  -H 'Content-Type: application/json' \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "min_age": "0ms",
          "actions": {
            "rollover": {
              "max_age": "30d",
              "max_size": "50gb"
            }
          }
        },
        "warm": {
          "min_age": "30d",
          "actions": {
            "shrink": {
              "number_of_shards": 1
            },
            "forcemerge": {
              "max_num_segments": 1
            }
          }
        },
        "delete": {
          "min_age": "90d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }'
```

## Verify

### Verify Elasticsearch Cluster Health

```bash
# Check cluster health
curl -s -u elastic:your_password "http://localhost:9200/_cluster/health?pretty"

# Check nodes
curl -s -u elastic:your_password "http://localhost:9200/_cat/nodes?v"

# Check indices
curl -s -u elastic:your_password "http://localhost:9200/_cat/indices?v"
```

### Verify Log Ingestion

```bash
# Check if logs are being indexed
curl -s -u elastic:your_password "http://localhost:9200/filebeat-*/_count"

# Search for recent logs
curl -s -u elastic:your_password "http://localhost:9200/filebeat-*/_search?pretty&q=*&size=5"
```

### Verify Kibana Connectivity

```bash
# Check Kibana status
curl -s -u elastic:your_password "http://localhost:5601/api/status"

# Check available spaces
curl -s -u elastic:your_password "http://localhost:5601/api/spaces/space/_find"
```

## Rollback

### Stop All Services

```bash
sudo systemctl stop filebeat
sudo systemctl stop kibana
sudo systemctl stop logstash
sudo systemctl stop elasticsearch
```

### Remove ELK Components

```bash
# Stop and disable services
sudo systemctl disable filebeat kibana logstash elasticsearch

# Remove installation directories
sudo rm -rf /opt/elk
sudo rm -rf /var/lib/elasticsearch
sudo rm -rf /var/log/elasticsearch
sudo rm -rf /var/log/kibana

# Remove systemd service files
sudo rm /etc/systemd/system/elasticsearch.service
sudo rm /etc/systemd/system/logstash.service
sudo rm /etc/systemd/system/kibana.service
sudo rm /etc/systemd/system/filebeat.service

# Reload systemd
sudo systemctl daemon-reload
```

### Restore Kernel Parameters

```bash
# Edit /etc/sysctl.conf and remove:
# vm.max_map_count=262144
# fs.file-max=65536

# Edit /etc/security/limits.conf and remove:
# elk soft nofile 65536
# elk hard nofile 65536
# elk soft nproc 4096
# elk hard nproc 4096
```

## Common Errors

### Error: "max_map_count" error during Elasticsearch startup

**Solution**: The kernel parameter wasn't applied correctly:

```bash
sudo sysctl -w vm.max_map_count=262144
sudo sysctl -w fs.file-max=65536

# Make permanent
echo "vm.max_map_count=262144" | sudo tee /etc/sysctl.d/99-elasticsearch.conf
echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.d/99-elasticsearch.conf
```

### Error: "OutOfMemoryError" Elasticsearch heap size

**Solution**: Adjust JVM heap size:

```bash
# Edit /etc/elasticsearch/jvm.options.d/heap.options
sudo cat > /etc/elasticsearch/jvm.options.d/heap.options <<EOF
-Xms4g
-Xmx4g
EOF

sudo systemctl restart elasticsearch
```

### Error: "Connection refused" on port 5044 (Logstash)

**Solution**: Check if Logstash is running and the port is open:

```bash
# Check Logstash status
sudo systemctl status logstash

# Check if port is listening
sudo ss -tlnp | grep 5044

# Check Logstash logs
sudo journalctl -u logstash -f
```

### Error: Kibana won't start after Elasticsearch password change

**Solution**: Update Kibana configuration with new password:

```bash
sudo cat > /etc/kibana/kibana.yml <<EOF
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
elasticsearch.username: "elastic"
elasticsearch.password: "your_new_password"
EOF

sudo systemctl restart kibana
```

### Error: Filebeat not sending logs to Logstash

**Solution**: Verify Filebeat configuration and connectivity:

```bash
# Test connectivity to Logstash
telnet logstash-server.example.com 5044

# Check Filebeat logs
sudo journalctl -u filebeat -f

# Test Filebeat configuration
sudo filebeat test config
```

### Error: "Index template error" in Kibana

**Solution**: Refresh the index pattern or recreate it:

1. Go to **Stack Management** → **Index Patterns**
2. Delete the existing pattern
3. Create a new index pattern with the correct name

## References

- [Elasticsearch Documentation](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Logstash Documentation](https://www.elastic.co/guide/en/logstash/current/index.html)
- [Kibana Documentation](https://www.elastic.co/guide/en/kibana/current/index.html)
- [Filebeat Documentation](https://www.elastic.co/guide/en/beats/filebeat/current/index.html)
- [Elasticsearch Security Settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-settings.html)
- [Elasticsearch Performance Tuning](https://www.elastic.co/guide/en/elasticsearch/reference/current/tune-for-indexing-speed.html)
