# Linux Wazuh SIEM Deployment

## Purpose

Deploy a complete security information and event management (SIEM) solution using Wazuh on Linux. This project covers Wazuh server installation, agent deployment, alerting configuration, and integration with existing security tooling.

## When to use

- Building an open-source SIEM for log aggregation and threat detection
- Centralizing security monitoring across multiple Linux servers
- Meeting compliance requirements (PCI-DSS, HIPAA, SOC 2) for log retention and alerting
- Detecting intrusions, malware, and suspicious behavior in real-time
- Creating audit trails for forensic analysis and incident response

## Prerequisites

### System Requirements
- Wazuh Server: Ubuntu 20.04+ or RHEL 8+, 4+ CPU cores, 8GB+ RAM, 100GB+ storage
- Wazuh Agents: Any Linux distribution supported by Wazuh agent
- Network connectivity between agents and server on ports 1514, 1515, 55000

### Software Requirements
- Root or sudo access on all target systems
- OpenSSL for certificate generation
- curl or wget for downloading packages

### Knowledge Requirements
- Basic understanding of Linux system administration
- Familiarity with logging concepts and SIEM architecture
- Understanding of network ports and firewall configuration

## Steps

### 1. Prepare Wazuh Server

Update system packages and install dependencies:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl apt-transport-https gnupg bc wget
```

Add Wazuh repository:

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh-archive-keyring.gpg] https://packages.wazuh.com/4.x/apt stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
```

### 2. Install Wazuh Server Components

Install the Wazuh manager:

```bash
sudo WAZUH_MANAGER="192.168.1.100" apt install -y wazuh-manager
```

Install the Wazuh API (required for dashboard):

```bash
sudo apt install -y wazuh-api
```

Install the Wazuh indexer (formerly Elasticsearch):

```bash
sudo apt install -y wazuh-indexer
```

Install the Wazuh dashboard:

```bash
sudo apt install -y wazuh-dashboard
```

### 3. Configure Wazuh Manager

Edit the manager configuration:

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Configure the following sections:

```xml
<global>
  <jsonout_output>yes</jsonout_output>
  <alerts_log>yes</alerts_log>
  <logall>yes</logall>
  <logall_json>yes</logall_json>
</global>

<remote>
  <connection>secure</connection>
  <port>1514</port>
  <protocol>tcp</protocol>
</remote>

<syslog>
  <enabled>yes</enabled>
  <level>all</level>
  <format>json</format>
</syslog>
```

Restart the manager:

```bash
sudo systemctl restart wazuh-manager
```

### 4. Configure Wazuh Indexer

Edit the indexer configuration:

```bash
sudo nano /etc/wazuh-indexer/opensearch.yml
```

Set the following:

```yaml
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
security.enabled: true
opensearch.security.authz.admin RolesMapping
```

Generate admin certificates:

```bash
sudo /usr/share/wazuh-indexer/plugins/opensearch-security/tools/install_demo_configuration.sh
```

Start the indexer:

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-indexer
sudo systemctl start wazuh-indexer
```

### 5. Configure Wazuh Dashboard

Edit the dashboard configuration:

```bash
sudo nano /etc/wazuh-dashboard/opensearch_dashboards.yml
```

Set:

```yaml
opensearch.hosts: https://localhost:9200
opensearch.ssl.verificationMode: none
```

Start the dashboard:

```bash
sudo systemctl enable wazuh-dashboard
sudo systemctl start wazuh-dashboard
```

### 6. Install Wazuh Agents

On Ubuntu/Debian agents:

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh-archive-keyring.gpg] https://packages.wazuh.com/4.x/apt stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
sudo WAZUH_MANAGER="192.168.1.100" WAZUH_AGENT_NAME="web-server-01" apt install -y wazuh-agent
```

On RHEL/CentOS agents:

```bash
sudo curl -o /etc/yum.repos.d/wazuh.repo https://packages.wazuh.com/4.x/yum/wazuh.repo
sudo WAZUH_MANAGER="192.168.1.100" WAZUH_AGENT_NAME="db-server-01" yum install -y wazuh-agent
```

Start the agent:

```bash
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

### 7. Configure Agent Scanning

Configure what the agent monitors:

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Enable relevant modules:

```xml
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/syslog</location>
</localfile>

<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/auth.log</location>
</localfile>

<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/apache2/access.log</location>
</localfile>

<rootcheck>
  <rootkit_files>yes</rootkit_files>
  <rootkit_trojans>yes</rootkit_trojans>
  <system_audit>yes</system_audit>
</rootcheck>

<syscheck>
  <frequency>3600</frequency>
  <scan_on_start>yes</scan_on_start>
  <alert_new_files>yes</alert_new_files>
  <directories>/etc,/usr/bin,/usr/sbin</directories>
</syscheck>
```

### 8. Create Custom Rules

Add detection rules:

```bash
sudo nano /var/ossec/etc/rules/local_rules.xml
```

Example rules:

```xml
<group name="custom-security">
  <rule id="100001" level="7">
    <if_sid>5716</if_sid>
    <match>authentication failure</match>
    <description>Multiple authentication failures detected</description>
  </rule>

  <rule id="100002" level="10">
    <if_sid>5716</if_sid>
    <match>BREAK-IN</match>
    <description>Possible break-in attempt detected</description>
  </rule>

  <rule id="100003" level="8">
    <if_sid>5716</if_sid>
    <match>sudo: COM</match>
    <description>sudo command executed</description>
  </rule>

  <rule id="100004" level="5">
    <if_sid>530</if_sid>
    <action>su</action>
    <description>User used su command</description>
  </rule>
</group>
```

### 9. Configure Active Response

Enable blocking actions:

```bash
sudo nano /var/ossec/etc/ossec.conf
```

```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>100002</rules_id>
</active-response>
```

### 10. Verify Deployment

Check manager status:

```bash
sudo /var/ossec/bin/agent_control -lc
```

Check agent connection:

```bash
sudo /var/ossec/bin/agent_control -list
```

Verify dashboard:

```bash
curl -k -u admin:admin https://localhost:5601/app/wazuh
```

Check indexer health:

```bash
curl -k https://localhost:9200/_cluster/health?pretty
```

## Verify

### Verify Agent Registration

```bash
sudo /var/ossec/bin/agent_control -lc
```

Expected output shows agent status as "Active".

### Verify Alert Generation

Trigger a test event:

```bash
logger "Test alert from Wazuh agent"
```

Check alerts in dashboard or:

```bash
tail -f /var/ossec/logs/alerts/alerts.log | grep "Test alert"
```

### Verify File Integrity Monitoring

Check syscheck alerts:

```bash
tail -f /var/ossec/logs/alerts/alerts.log | grep "syscheck"
```

### Verify Dashboard Access

Access: https://your-server-ip:5601
Default credentials: admin / admin

## Rollback

### Remove Wazuh Agent

```bash
sudo systemctl stop wazuh-agent
sudo apt remove -y wazuh-agent
sudo rm -rf /var/ossec
```

### Remove Wazuh Server

```bash
sudo systemctl stop wazuh-manager wazuh-dashboard wazuh-indexer
sudo apt remove -y wazuh-manager wazuh-api wazuh-dashboard wazuh-indexer
sudo rm -rf /var/ossec /etc/wazuh-indexer /etc/wazuh-dashboard /usr/share/wazuh-indexer /usr/share/wazuh-dashboard
```

### Restore Network Rules

If active response blocked legitimate traffic:

```bash
sudo iptables -L INPUT -n | grep DROP
sudo iptables -D INPUT -j firewall-drop
```

## Common errors

### "Cannot connect to Wazuh manager"

**Problem:** Agent cannot reach the manager on port 1514/1515.

**Solution:**

```bash
sudo systemctl status wazuh-manager
sudo firewall-cmd --add-port=1514/tcp --permanent
sudo firewall-cmd --reload
telnet 192.168.1.100 1514
```

### "Indexer cluster is red"

**Problem:** Elasticsearch/OpenSearch indexer health is red.

**Solution:**

```bash
sudo systemctl restart wazuh-indexer
curl -k https://localhost:9200/_cluster/health?pretty
```

Check disk space:

```bash
df -h /var/lib/wazuh-indexer
```

### "Dashboard cannot connect to indexer"

**Problem:** Dashboard shows "Unable to connect to Wazuh API".

**Solution:**

```bash
sudo systemctl status wazuh-manager
curl -k https://localhost:55000/version
sudo cat /etc/wazuh-dashboard/opensearch_dashboards.yml
```

Regenerate Wazuh API credentials:

```bash
sudo /usr/share/wazuh-api/generate_auth.sh
```

### "Agent enrollment failed"

**Problem:** Agent shows "Not connected" after installation.

**Solution:**

```bash
sudo systemctl status wazuh-agent
sudo grep -r "Manager" /var/ossec/etc/ossec.conf
sudo /var/ossec/bin/agent_control -r -d <agent_id>
```

### "No alerts in dashboard"

**Problem:** Dashboard shows no events.

**Solution:**

```bash
sudo ls -la /var/ossec/logs/alerts/
sudo /var/ossec/bin/wazuh-logtest
```

Check localfile configuration is correct.

## References

- Wazuh Documentation: https://documentation.wazuh.com/current/index.html
- Wazuh Agent Installation: https://documentation.wazuh.com/current/installation-guide/wazuh-agent/index.html
- Wazuh Rules and Decoders: https://documentation.wazuh.com/current/user-manual/rules-class/rules-class.html
- Active Response Configuration: https://documentation.wazuh.com/current/user-manual/capabilities/active-response/index.html
- Wazuh API Reference: https://documentation.wazuh.com/current/api-reference/index.html
- OpenSCAP Integration: https://documentation.wazuh.com/current/user-manual/capabilities/vulnerability-detection.html
- File Integrity Monitoring: https://documentation.wazuh.com/current/user-manual/capabilities/file-integrity/index.html