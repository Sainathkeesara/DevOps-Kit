# Centralized Logging with syslog-ng and Logstash

## Purpose

Set up a production-grade centralized logging pipeline on Linux using syslog-ng as the log collector and router, and Logstash as the log processor and enrichment engine. This walkthrough covers multi-source log collection, parsing, enrichment, and forwarding to Elasticsearch for search and visualization.

## When to use

- Centralizing logs from multiple Linux servers into a single searchable platform
- Replacing rsyslog with syslog-ng for advanced routing, filtering, and parsing
- Building a log pipeline that normalizes diverse log formats (syslog, JSON, Apache, auth)
- Enriching logs with GeoIP, DNS lookups, or metadata before indexing
- Compliance environments requiring tamper-evident log collection (SOC 2, PCI-DSS, HIPAA)
- High-throughput log environments (>10K events/sec) needing backpressure and buffering

## Prerequisites

- Linux server (Ubuntu 22.04 or RHEL 9) with 4+ CPU cores, 8 GB RAM, 100 GB storage
- Root or sudo access on the logging server
- Network connectivity: UDP/TCP 514 (syslog), TCP 5044 (Logstash Beats input), TCP 9200 (Elasticsearch)
- Domain names or IPs of source servers to collect logs from
- Java 17+ installed for Logstash (`java -version` to check)

## Steps

### Step 1: Install syslog-ng

On Ubuntu 22.04:

```bash
sudo apt-get update
sudo apt-get install -y syslog-ng syslog-ng-mod-json syslog-ng-mod-geoip
```

On RHEL 9:

```bash
sudo dnf install -y syslog-ng syslog-ng-json syslog-ng-geoip
```

Verify installation:

```bash
syslog-ng --version
# Expected: syslog-ng 4.x or later
```

### Step 2: Install Logstash

```bash
# Add Elastic GPG key and repository
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update
sudo apt-get install -y logstash
```

Verify:

```bash
/usr/share/logstash/bin/logstash --version
```

### Step 3: Configure syslog-ng as collector

Backup the default config:

```bash
sudo cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf.bak.$(date +%Y%m%d)
```

Copy the template configuration:

```bash
sudo cp templates/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf
```

The template configures:
- **Source:** Listens on UDP/TCP 514 for remote syslog, plus `/dev/log` for local
- **Filters:** Separates auth, kern, cron, and application logs
- **Destination:** Writes structured JSON to `/var/log/centralized/` and forwards to Logstash via TCP 5140
- **Rewrite:** Adds hostname and receipt timestamp to every message

Validate the configuration:

```bash
sudo syslog-ng --syntax-only
# Expected: no output (syntax OK)
```

### Step 4: Configure Logstash pipeline

Copy the pipeline configuration:

```bash
sudo mkdir -p /etc/logstash/conf.d
sudo cp templates/logstash/logstash.conf /etc/logstash/conf.d/centralized-logging.conf
```

The pipeline does:
- **Input:** Accepts syslog-ng JSON output on TCP 5140 and Beats on TCP 5044
- **Filter:** Parses syslog timestamps, extracts severity/facility, enriches with GeoIP for SSH auth logs
- **Output:** Sends to Elasticsearch with daily index rotation

Validate the Logstash config:

```bash
sudo /usr/share/logstash/bin/logstash --config.test_and_exit -f /etc/logstash/conf.d/centralized-logging.conf
# Expected: Configuration OK
```

### Step 5: Install and configure Elasticsearch (if not already present)

```bash
sudo apt-get install -y elasticsearch
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
```

Wait for Elasticsearch to be ready:

```bash
until curl -s http://localhost:9200/_cluster/health | grep -q '"status"'; do
  echo "Waiting for Elasticsearch..."
  sleep 5
done
curl -s http://localhost:9200/_cluster/health | python3 -m json.tool
```

### Step 6: Create index template in Elasticsearch

```bash
curl -X PUT "http://localhost:9200/_index_template/centralized-logs" \
  -H 'Content-Type: application/json' \
  -d '{
  "index_patterns": ["centralized-logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 2,
      "number_of_replicas": 1,
      "index.lifecycle.name": "logs-retention-90d",
      "index.lifecycle.rollover_alias": "centralized-logs"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "hostname": { "type": "keyword" },
        "program": { "type": "keyword" },
        "severity": { "type": "keyword" },
        "facility": { "type": "keyword" },
        "message": { "type": "text", "analyzer": "standard" },
        "source_ip": { "type": "ip" },
        "geoip": {
          "properties": {
            "location": { "type": "geo_point" },
            "country_name": { "type": "keyword" },
            "city_name": { "type": "keyword" }
          }
        }
      }
    }
  }
}'
```

### Step 7: Start services and verify log flow

```bash
# Start syslog-ng
sudo systemctl enable syslog-ng
sudo systemctl restart syslog-ng
sudo systemctl status syslog-ng

# Start Logstash
sudo systemctl enable logstash
sudo systemctl restart logstash
sudo journalctl -u logstash -f --no-pager | head -20
```

### Step 8: Configure source servers to forward logs

On each source server, configure rsyslog or syslog-ng to forward to the logging server:

```bash
# Using rsyslog on source servers
echo '*.* @@logging-server.example.com:514' | sudo tee /etc/rsyslog.d/60-centralized.conf
sudo systemctl restart rsyslog
```

Or using syslog-ng on source servers:

```bash
# Add to /etc/syslog-ng/syslog-ng.conf on source
# destination d_remote { tcp("logging-server.example.com" port(514)); };
# log { source(s_src); destination(d_remote); };
```

### Step 9: Verify end-to-end log flow

Generate a test log on a source server:

```bash
logger -p local0.info "TEST_LOG_MESSAGE from $(hostname) at $(date -Iseconds)"
```

On the logging server, verify the log appears in Elasticsearch:

```bash
curl -s "http://localhost:9200/centralized-logs-*/_search?q=message:TEST_LOG_MESSAGE&size=1" | python3 -m json.tool
```

Verify syslog-ng parsed fields:

```bash
tail -5 /var/log/centralized/all.json | python3 -m json.tool
```

## Verify

1. Check syslog-ng is receiving logs:
```bash
sudo syslog-ng --stats
# Look for: source.remote_tcp.processed — should be > 0
```

2. Check Logstash pipeline health:
```bash
curl -s http://localhost:9600/_node/stats/pipelines | python3 -m json.tool | grep -A5 events
```

3. Check Elasticsearch has recent documents:
```bash
curl -s "http://localhost:9200/centralized-logs-*/_count" | python3 -m json.tool
```

4. Verify log rotation is configured:
```bash
cat /etc/logrotate.d/centralized-logs
```

5. Check service status:
```bash
systemctl is-active syslog-ng logstash elasticsearch
```

## Rollback

### Stop and disable services
```bash
sudo systemctl stop logstash syslog-ng elasticsearch
sudo systemctl disable logstash syslog-ng elasticsearch
```

### Restore original syslog-ng config
```bash
sudo cp /etc/syslog-ng/syslog-ng.conf.bak.* /etc/syslog-ng/syslog-ng.conf
sudo systemctl restart syslog-ng
```

### Remove forwarded logs from source servers
```bash
# On each source server
sudo rm -f /etc/rsyslog.d/60-centralized.conf
sudo systemctl restart rsyslog
```

### Remove packages (optional)
```bash
sudo apt-get remove -y logstash elasticsearch
sudo apt-get autoremove -y
```

## Common errors

### Error: "syslog-ng: Error parsing config file, syntax error"

**Symptom:** `syslog-ng --syntax-only` reports an error at a specific line.

**Solution:** Check for mismatched braces or missing semicolons in the config. Common cause: copying the template without adjusting the `source` network interface. Run `syslog-ng --syntax-only` after each edit to isolate the line.

### Error: "Logstash Pipeline terminating because of LoadError: no such file to load -- geoip"

**Symptom:** Logstash crashes on startup with GeoIP plugin error.

**Solution:** Install the GeoIP database:
```bash
sudo mkdir -p /usr/share/GeoIP
sudo wget -O /usr/share/GeoIP/GeoLite2-City.mmdb https://github.com/maxmind/MaxMind-DB/raw/main/test-data/GeoLite2-City.tgz
# Or disable the geoip filter in logstash.conf if GeoIP enrichment is not needed
```

### Error: "Elasticsearch cluster health is yellow"

**Symptom:** Cluster status is yellow instead of green.

**Solution:** Yellow means primary shards are allocated but replicas are not. For single-node dev setups, set replicas to 0:
```bash
curl -X PUT "http://localhost:9200/centralized-logs-*/_settings" \
  -H 'Content-Type: application/json' \
  -d '{"index.number_of_replicas": 0}'
```

### Error: "Connection refused on port 514"

**Symptom:** Source servers cannot connect to syslog-ng.

**Solution:** Verify the firewall allows inbound UDP/TCP 514:
```bash
sudo ufw allow 514/tcp
sudo ufw allow 514/udp
# Or for firewalld:
sudo firewall-cmd --permanent --add-port=514/tcp
sudo firewall-cmd --permanent --add-port=514/udp
sudo firewall-cmd --reload
```

Also check syslog-ng is listening:
```bash
ss -tlnp | grep 514
```

### Error: "Logstash heap space OutOfMemoryError"

**Symptom:** Logstash crashes with Java heap errors.

**Solution:** Increase JVM heap size in `/etc/logstash/jvm.options`:
```
-Xms2g
-Xmx2g
```
Restart Logstash after changing.

### Error: "syslog-ng drops messages under load"

**Symptom:** High log volume causes message drops.

**Solution:** Increase log-fetch-limit and enable disk buffering in syslog-ng.conf:
```
destination d_logstash {
    tcp("logging-server" port(5140)
        log-fifo-size(100000)
        disk-buffer(
            mem-buf-size(2097152)
            disk-buf-size(536870912)
            reliable(yes)
        )
    );
};
```

## References

- [syslog-ng Administration Guide](https://www.syslog-ng.com/technical-documents/) (2026-01-15)
- [syslog-ng Configuration Reference](https://www.syslog-ng.com/technical-documents/doc/syslog-ng-open-source-edition/3.38/administration-guide/) (2026-01-15)
- [Logstash Reference](https://www.elastic.co/guide/en/logstash/current/index.html) (2026-02-01)
- [Logstash Syslog Input Plugin](https://www.elastic.co/guide/en/logstash/current/plugins-inputs-syslog.html) (2026-02-01)
- [Elasticsearch Index Templates](https://www.elastic.co/guide/en/elasticsearch/reference/current/index-templates.html) (2026-02-01)
- [GeoIP Filter Plugin](https://www.elastic.co/guide/en/logstash/current/plugins-filters-geoip.html) (2026-02-01)
- [syslog-ng Disk Buffering](https://www.syslog-ng.com/technical-documents/doc/syslog-ng-open-source-edition/3.38/administration-guide/96) (2026-01-15)
