# Jenkins CLI Commands Reference
Common Jenkins CLI commands for sysadmins

## Purpose
This document provides quick reference CLI commands for Jenkins administration and operations.

## When to use
- Quick reference for common Jenkins operations
- Copy-paste into scripts or terminal
- Automation of Jenkins tasks

## Prerequisites
- Jenkins instance running (LTS 2.541+)
- jenkins-cli.jar or curl access
- API token for authentication

## Commands

### Job Management
```bash
# List all jobs
java -jar jenkins-cli.jar -s http://jenkins:8080 list-jobs

# Create a new job from XML
java -jar jenkins-cli.jar -s http://jenkins:8080 create-job myjob < config.xml

# Copy a job
java -jar jenkins-cli.jar -s http://jenkins:8080 copy-job source-job target-job

# Delete a job
java -jar jenkins-cli.jar -s http://jenkins:8080 delete-job myjob

# Enable/Disable a job
java -jar jenkins-cli.jar -s http://jenkins:8080 enable-job myjob
java -jar jenkins-cli.jar -s http://jenkins:8080 disable-job myjob
```

### Build Operations
```bash
# Trigger a build
java -jar jenkins-cli.jar -s http://jenkins:8080 build myjob

# Trigger a parameterized build
java -jar jenkins-cli.jar -s http://jenkins:8080 build -p PARAM1=value1 -p PARAM2=value2 myjob

# Get build console output
java -jar jenkins-cli.jar -s http://jenkins:8080 console myjob 42

# Stop a build
java -jar jenkins-cli.jar -s http://jenkins:8080 stop-build myjob 42

# List build queue
java -jar jenkins-cli.jar -s http://jenkins:8080 queue-list

# Cancel a queue item
java -jar jenkins-cli.jar -s http://jenkins:8080 cancel-queue-build 42
```

### Node/Agent Management
```bash
# List all nodes/agents
java -jar jenkins-cli.jar -s http://jenkins:8080 list-nodes

# Create a permanent agent
java -jar jenkins-cli.jar -s http://jenkins:8080 create-node agent1 -d /home/jenkins/agent1 -f agent1-launcher.xml

# Connect an agent
java -jar jenkins-cli.jar -s http://jenkins:8080 connect-node agent1

# Disconnect an agent
java -jar jenkins-cli.jar -s http://jenkins:8080 disconnect-node agent1

# Delete an agent
java -jar jenkins-cli.jar -s http://jenkins:8080 delete-node agent1

# Get agent log
java -jar jenkins-cli.jar -s http://jenkins:8080 agent-log agent1
```

### Plugin Management
```bash
# List installed plugins
java -jar jenkins-cli.jar -s http://jenkins:8080 list-plugins

# Install a plugin
java -jar jenkins-cli.jar -s http://jenkins:8080 install-plugin pipeline

# Uninstall a plugin
java -jar jenkins-cli.jar -s http://jenkins:8080 uninstall-plugin pipeline

# Check plugin updates
java -jar jenkins-cli.jar -s http://jenkins:8080 plugin-initialised
```

### Credential Management
```bash
# Add username/password credential
curl -X POST http://jenkins:8080/credentials/store/folder/store/credential -u user:token \
  -d '{\"id\": \"mycreds\", \"type\": \"UsernamePasswordCredentialsImpl\", \"username\": \"deploy\", \"password\": \"secret\"}'

# List credentials
curl -u user:token http://jenkins:8080/credentials/api/json

# Update credential
curl -X PUT http://jenkins:8080/credentials/store/folder/store/credential/mycreds -u user:token -d '{\"password\": \"newsecret\"}'

# Delete credential
curl -X DELETE http://jenkins:8080/credentials/store/folder/store/credential/mycreds -u user:token
```

### Pipeline Commands
```bash
# Validate Jenkinsfile
java -jar jenkins-cli.jar -s http://jenkins:8080 declarative-linter < Jenkinsfile

# Run pipeline from file
java -jar jenkins-cli.jar -s http://jenkins:8080 replay-pipeline myjob < pipeline.groovy

# Get pipeline steps
java -jar jenkins-cli.jar -s http://jenkins:8080 get-plugins
```

### System Information
```bash
# Get system information
java -jar jenkins-cli.jar -s http://jenkins:8080 systemInfo

# Get Jenkins version
java -jar jenkins-cli.jar -s http://jenkins:8080 version

# Get JVM information
java -jar jenkins-cli.jar -s http://jenkins:8080 java-version

# Reload configuration
java -jar jenkins-cli.jar -s http://jenkins:8080 reload-configuration
```

### User Management
```bash
# Create user
curl -X POST http://jenkins:8080/securityRealm/createAccountByAdmin -u admin:token \
  -d 'username=newuser&password=newpass&fullname=New User'

# List users
curl -u user:token http://jenkins:8080/securityRealm/api/json | jq '.users[]'

# Disable user
curl -X POST http://jenkins:8080/securityRealm/user/newuser/disable -u admin:token
```

### View Management
```bash
# Create a new view
java -jar jenkins-cli.jar -s http://jenkins:8080 create-view myview

# Delete a view
java -jar jenkins-cli.jar -s http://jenkins:8080 delete-view myview

# Add job to view
java -jar jenkins-cli.jar -s http://jenkins:8080 add-job-to-view myview myjob
```

### Using REST API with curl
```bash
# Get JSON API
curl -u user:token http://jenkins:8080/api/json

# Get job information
curl -u user:token http://jenkins:8080/job/myjob/api/json

# Get build information
curl -u user:token http://jenkins:8080/job/myjob/42/api/json

# Trigger build via REST
curl -X POST http://jenkins:8080/job/myjob/build -u user:token

# Get queue information
curl -u user:token http://jenkins:8080/queue/api/json

# Get computer (nodes) information
curl -u user:token http://jenkins:8080/computer/api/json
```

### Script Console
```bash
# Run Groovy script via CLI
java -jar jenkins-cli.jar -s http://jenkins:8080 groovy script.groovy

# Run Groovy script via REST
curl -X POST http://jenkins:8080/scriptText -u user:token \
  -d 'script=Jenkins.instance.plugins' 
```

### Archives and Logs
```bash
# Get build artifacts
curl -u user:token http://jenkins:8080/job/myjob/42/artifact/build.log

# Get workspace
curl -u user:token http://jenkins:8080/job/myjob/42/workspace/*zip*/myjob.zip

# Get fingerprint records
curl -u user:token http://jenkins:8080/fingerprint/api/json
```

### Master and Agent Communication
```bash
# Run command on agent
java -jar jenkins-cli.jar -s http://jenkins:8080 remoting agent1 "hostname"

# Transfer file to agent
java -jar jenkins-cli.jar -s http://jenkins:8080 connect-node agent1

# Check agent availability
curl -u user:token http://jenkins:8080/computer/agent1/api/json
```

## Verify
Test each command in a non-production Jenkins instance first:
```bash
# Verify CLI connectivity
java -jar jenkins-cli.jar -s http://jenkins:8080 who-am-i

# Verify authentication
curl -u user:token http://jenkins:8080/api/json | jq '.mode'
```

## Rollback
For accidental deletions or modifications:
- Use Jenkins backup plugin
- Use configuration as code plugin for version control
- Keep XML backups: `java -jar jenkins-cli.jar -s http://jenkins:8080 get-job myjob > myjob.xml`

## Common errors
- `Authentication required` — generate API token from Jenkins UI → user → configure → API token
- `No such file or directory` — ensure jenkins-cli.jar is present
- `403 Forbidden` — check Overall/Read permission
- `Connection refused` — check Jenkins is running and port 8080 is accessible
- `Missing CRUMB` — add `-crumb` flag to CLI commands

## References
- https://www.jenkins.io/doc/book/managing/cli/
- https://www.jenkins.io/doc/book/using/
- https://javadoc.jenkins.io/