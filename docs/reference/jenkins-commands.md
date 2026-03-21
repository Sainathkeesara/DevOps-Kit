# Jenkins Commands Reference

## Purpose

This reference provides 50+ Jenkins CLI commands for common administrative and operational tasks. Commands are organized by category and include pipes/filter combinations where applicable.

## When to use

- Managing Jenkins jobs and builds
- Pipeline troubleshooting and debugging
- Scripting Jenkins automation
- Administrative tasks via CLI

## Prerequisites

- Jenkins installed and accessible
- `jenkins-cli.jar` or `jenkins` command available
- API token configured for authentication
- Network access to Jenkins controller

## Commands

### Job Management

```bash
# List all jobs
jenkins-cli.jar ls-jobs

# Create a new job from XML
jenkins-cli.jar create-job myjob < job.xml

# Copy existing job
jenkins-cli.jar copy-job source-job target-job

# Delete a job
jenkins-cli.jar delete-job myjob

# Disable a job
jenkins-cli.jar disable-job myjob

# Enable a job
jenkins-cli.jar enable-job myjob

# Get job configuration
jenkins-cli.jar get-job myjob > myjob.xml

# Update job configuration
jenkins-cli.jar update-job myjob < new-config.xml

# List all job names with status
jenkins-cli.jar list-jobs | awk '{print $1}'

# Count jobs by regex
jenkins-cli.jar list-jobs | grep -c "pattern"

# Export all job configs
for job in $(jenkins-cli.jar list-jobs); do jenkins-cli.jar get-job "$job" > "$job.xml"; done
```

### Build Management

```bash
# Trigger a build
jenkins-cli.jar build myjob

# Trigger build with parameters
jenkins-cli.jar build myjob -p PARAM1=value1 -p PARAM2=value2

# Trigger downstream job
jenkins-cli.jar build -s downstream-job

# Get build console output
jenkins-cli.jar console myjob 42

# Get last build number
jenkins-cli.jar list-builds myjob | tail -1 | awk '{print $1}'

# Delete build
jenkins-cli.jar delete-builds myjob 42

# Keep build forever
jenkins-cli.jar keep-build myjob 42

# List builds with status
jenkins-cli.jar list-builds myjob | awk '{print $1, $3}'

# Get build cause
jenkins-cli.jar get-build myjob 42 | grep -A5 "cause"

# Trigger parameterized build
jenkins-cli.jar build -f -v myjob -p ENVIRONMENT=prod VERSION=1.2.3

# Get build timestamps
jenkins-cli.jar list-builds myjob | awk '{print $1, $5}'

# Archive build artifacts
jenkins-cli.jar keep-build myjob 42 --artifact

# Stop running build
jenkins-cli.jar stop-build myjob 42
```

### User and Security

```bash
# List users
jenkins-cli.jar list-users

# Add user to matrix
jenkins-cli.jar add-job-to-matrix myjob user@domain.comROLE=1

# Create user
jenkins-cli.jar create-user admin "Admin User" admin@example.com password

# Get user details
jenkins-cli.jar get-user admin

# List all API tokens
jenkins-cli.jar list-api-tokens admin

# Get security settings
jenkins-cli.jar get-security-config

# Update global security
jenkins-cli.jar set-security-config < security.xml

# Add credential
jenkins-cli.jar add-credentials -domain system -scope global username:password

# List credentials
jenkins-cli.jar list-credentials | grep -A2 "id:"
```

### Node/Agent Management

```bash
# List all nodes
jenkins-cli.jar list-nodes

# Create new agent
jenkins-cli.jar create-node myagent

# Delete agent
jenkins-cli.jar delete-node myagent

# Disable agent
jenkins-cli.jar disable-node myagent "Maintenance"

# Enable agent
jenkins-cli.jar enable-node myagent

# Get agent config
jenkins-cli.jar get-node myagent > node.xml

# Update agent config
jenkins-cli.jar update-node myagent < node.xml

# List agents with status
jenkins-cli.jar list-nodes | awk '{print $1, $3}'

# Check agent online/offline
jenkins-cli.jar list-nodes | grep -E "online|offline"

# Force agent online
jenkins-cli.jar connect-node myagent

# Disconnect agent
jenkins-cli.jar disconnect-node myagent
```

### Pipeline and Groovy

```bash
# Run Groovy script
jenkins-cli.jar groovy 'println(Jenkins.instance.pluginManager.plugins)'

# Execute pipeline
jenkins-cli.jar run-pipeline -f Jenkinsfile

# Validate Jenkinsfile
jenkins-cli.jar validate-jenkinsfile < Jenkinsfile

# Get pipeline steps
jenkins-cli.jar list-pipeline-steps myjob

# Retry failed pipeline stage
jenkins-cli.jar replay-pipeline myjob 42

# Abort pipeline
jenkins-cli.jar kill-pipeline myjob 42

# Get pipeline stage details
jenkins-cli.jar get-pipeline-stages myjob 42 | grep -A3 "stage"
```

### Plugin Management

```bash
# List installed plugins
jenkins-cli.jar list-plugins | awk '{print $1}'

# Install plugin
jenkins-cli.jar install-plugin git-client

# Update plugin
jenkins-cli.jar update-plugin git

# Uninstall plugin
jenkins-cli.jar uninstall-plugin git

# Check plugin dependencies
jenkins-cli.jar list-plugins | grep -B2 "required"

# Get plugin info
jenkins-cli.jar plugin-info git

# List active plugins
jenkins-cli.jar list-plugins | grep -c "active"

# Disable plugin
jenkins-cli.jar disable-plugin analysis-core

# Enable plugin
jenkins-cli.jar enable-plugin analysis-core
```

### Queue and Scheduling

```bash
# View build queue
jenkins-cli.jar list-queue

# Get queue item
jenkins-cli.jar get-queue-item 123

# Cancel queue item
jenkins-cli.jar cancel-queue 123

# List scheduled builds
jenkins-cli.jar list-scheduled-jobs

# Schedule periodic build
jenkins-cli.jar schedule-job myjob "H * * * *"

# Clear queue
jenkins-cli.jar clear-queue

# Get queue statistics
jenkins-cli.jar list-queue | wc -l
```

### System Information

```bash
# Get system info
jenkins-cli.jar system-info | grep -E "name|version|java"

# Get Jenkins version
jenkins-cli.jar version

# Get system metrics
jenkins-cli.jar get-system-metrics | grep -E "memory|thread|cpu"

# Reload configuration
jenkins-cli.jar reload-configuration

# Restart Jenkins
jenkins-cli.jar safe-restart

# Shutdown Jenkins
jenkins-cli.jar shutdown

# Get thread dump
jenkins-cli.jar thread-dump > threaddump.txt

# Get heap dump
jenkins-cli.jar heap-dump > heap.bin
```

### View and Dashboard

```bash
# Create view
jenkins-cli.jar create-view myview

# Delete view
jenkins-cli.jar delete-view myview

# Add job to view
jenkins-cli.jar add-job-to-view myview myjob

# Remove job from view
jenkins-cli.jar remove-job-from-view myview myjob

# List views
jenkins-cli.jar list-views

# Get view config
jenkins-cli.jar get-view myview > view.xml
```

### Logs and Diagnostics

```bash

# Get Jenkins logs
jenkins-cli.jar log | tail -100

# Get agent logs
jenkins-cli.jar node-log myagent | tail -50

# Stream build log
jenkins-cli.jar console-text myjob 42

# Get build cause
jenkins-cli.jar get-build-cause myjob 42 | jq -r '.[]'

# Search logs for errors
jenkins-cli.jar log | grep -i error | head -20

# Get exception trace
jenkins-cli.jar log | grep -A10 "Exception"

# Export build logs
jenkins-cli.jar console myjob 42 > build.log
```

### Backup and Restore

```bash
# Create backup
jenkins-cli.jar create-backup

# Restore from backup
jenkins-cli.jar restore-backup backup.zip

# Export job configs
jenkins-cli.jar list-jobs | while read job; do jenkins-cli.jar get-job "$job" > "backups/$job.xml"; done

# Import job configs
for f in *.xml; do jenkins-cli.jar update-job "$(basename $f .xml)" < "$f"; done

# Backup user content
jenkins-cli.jar backup-user-content

# Export all credentials
jenkins-cli.jar list-credentials | grep -A5 "id:"
```

### API and Automation

```bash
# Get API token
jenkins-cli.jar login --username admin --password xxxxx

# Usecrumb for API
curl -s http://jenkins:8080/crumb-issuer/api/json | jq -r '.crumb'

# Generic API call
curl -s -u admin:apitoken http://jenkins:8080/api/json | jq

# List jobs via API
curl -s -u admin:apitoken http://jenkins:8080/api/json | jq '.jobs[].name'

# Trigger build via API
curl -s -X POST -u admin:apitoken "http://jenkins:8080/job/myjob/build"

# Get build details via API
curl -s -u admin:apitoken "http://jenkins:8080/job/myjob/lastBuild/api/json" | jq

# Search builds
curl -s -u admin:apitoken "http://jenkins:8080/job/myjob/api/json?tree=builds[number,result]" | jq
```

## Verify

Test connectivity:
```bash
jenkins-cli.jar version
jenkins-cli.jar list-jobs | head -5
jenkins-cli.jar list-plugins | grep -c "active"
```

Verify authentication:
```bash
jenkins-cli.jar who-am-i
jenkins-cli.jar get-user admin
```

## Rollback

If commands fail due to permission issues:
1. Verify API token is valid
2. Check user has admin role in matrix-based security
3. Ensure network connectivity to Jenkins
4. Verify Java version compatibility with CLI

## Common Errors

### Error: "Authentication required"

Cause: Missing or invalid API token

Resolution:
```bash
# Generate token at: Jenkins > People > User > API Token
export JENKINS_USER=admin
export JENKINS_TOKEN=xxxxx
jenkins-cli.jar -auth $JENKINS_USER:$JENKINS_TOKEN list-jobs
```

### Error: "No such file or directory: jenkins-cli.jar"

Cause: CLI not downloaded

Resolution:
```bash
wget http://jenkins:8080/jnlp/jenkins-cli.jar
```

### Error: "Connection refused"

Cause: Jenkins not running or firewall blocking

Resolution:
```bash
# Check Jenkins is running
systemctl status jenkins
# Check port
netstat -tuln | grep 8080
```

### Error: "No crumb was provided"

Cause: CSRF protection enabled

Resolution:
```bash
# Use crumb
CRUMB=$(curl -s http://jenkins:8080/crumb-issuer/api/json | jq -r '.crumb')
curl -X POST -H "Jenkins-Crumb:$CRUMB" ...
```

### Error: "Permission denied"

Cause: User lacks required permission

Resolution:
Add user to matrix or enable appropriate role in Role-Based Strategy

## References

- Jenkins CLI Documentation: https://www.jenkins.io/doc/book/managing/cli/
- Jenkins API: https://www.jenkins.io/doc/book/using/remote-access-api/
- Jenkins Security: https://www.jenkins.io/doc/book/security/