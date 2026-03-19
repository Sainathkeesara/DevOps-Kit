# Jenkins Commands Reference

A comprehensive reference guide for Jenkins CLI commands, administration, and pipeline operations.

## Table of Contents
1. [CLI Overview](#cli-overview)
2. [Job Management](#job-management)
3. [Build Operations](#build-operations)
4. [Node/Agent Management](#nodeagent-management)
5. [Plugin Management](#plugin-management)
6. [Credential Management](#credential-management)
7. [Pipeline Commands](#pipeline-commands)
8. [System Information](#system-information)
9. [User Management](#user-management)
10. [View Management](#view-management)

---

## CLI Overview

### Connecting to Jenkins CLI

```bash
# Connect via HTTP (default port 8080)
java -jar jenkins-cli.jar -s http://localhost:8080/ who-am-i

# Connect via SSH (requires SSH key setup)
ssh -o StrictHostKeyChecking=no user@localhost -p 22 help

# Connect with authentication
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth user:token who-am-i

# Using curl for API calls
curl -u user:token http://localhost:8080/api/json
```

### CLI Help

```bash
# List all available commands
java -jar jenkins-cli.jar -s http://localhost:8080/ help

# Get help for specific command
java -jar jenkins-cli.jar -s http://localhost:8080/ help build

# List all jobs
java -jar jenkins-cli.jar -s http://localhost:8080/ list-jobs
```

---

## Job Management

### Creating Jobs

```bash
# Create a new job from XML
java -jar jenkins-cli.jar -s http://localhost:8080/ create-job my-job < job.xml

# Create job from config file
java -jar jenkins-cli.jar -s http://localhost:8080/ create-job my-new-job < /path/to/config.xml

# Copy existing job
java -jar jenkins-cli.jar -s http://localhost:8080/ copy-job source-job target-job
```

### Deleting and Managing Jobs

```bash
# Delete a job
java -jar jenkins-cli.jar -s http://localhost:8080/ delete-job my-job

# Disable a job
java -jar jenkins-cli.jar -s http://localhost:8080/ disable-job my-job

# Enable a job
java -jar jenkins-cli.jar -s http://localhost:8080/ enable-job my-job

# Rename a job
java -jar jenkins-cli.jar -s http://localhost:8080/ rename-job old-name new-name

# Get job configuration
java -jar jenkins-cli.jar -s http://localhost:8080/ get-job my-job > config.xml

# Update job configuration
java -jar jenkins-cli.jar -s http://localhost:8080/ update-job my-job < new-config.xml

# Reload configuration from disk
java -jar jenkins-cli.jar -s http://localhost:8080/ reload
```

### Listing and Querying Jobs

```bash
# List all jobs
java -jar jenkins-cli.jar -s http://localhost:8080/ list-jobs

# List jobs with specific pattern
java -jar jenkins-cli.jar -s http://localhost:8080/ list-jobs '.*-dev'

# Get job info in JSON
curl -s -u user:token http://localhost:8080/job/my-job/api/json | jq .

# Get job's last build number
java -jar jenkins-cli.jar -s http://localhost:8080/ get-job my-job | grep -A5 'lastBuild'

# List all job names (using Python)
python3 -c "import json; print('\n'.join(json.load(__import__('urllib.request').urlopen('http://localhost:8080/api/json?tree=jobs[name]'))['jobs']))"
```

---

## Build Operations

### Triggering Builds

```bash
# Build a job (latest parameters)
java -jar jenkins-cli.jar -s http://localhost:8080/ build my-job

# Build with parameters
java -jar jenkins-cli.jar -s http://localhost:8080/ build my-job -p PARAM1=value1 -p PARAM2=value2

# Build with timeout (in seconds)
java -jar jenkins-cli.jar -s http://localhost:8080/ build my-job -t 300

# Build specific branch/tag
java -jar jenkins-cli.jar -s http://localhost:8080/ build my-job -s -v BRANCH=feature-branch

# Queue a build
java -jar jenkins-cli.jar -s http://localhost:8080/ queue-build my-job

# Schedule a build (cron format)
java -jar jenenkins-cli.jar -s http://localhost:8080/ schedule my-job 'H * * * *'

# Trigger build via curl
curl -X POST http://localhost:8080/job/my-job/build -u user:token

# Trigger with parameters via curl
curl -X POST http://localhost:8080/job/my-job/buildWithParameters \
  -u user:token \
  -d PARAM1=value1 \
  -d PARAM2=value2
```

### Monitoring Builds

```bash
# Get build console output
java -jar jenkins-cli.jar -s http://localhost:8080/ console my-job

# Get specific build console output
java -jar jenkins-cli.jar -s http://localhost:8080/ console my-job 42

# Stream console output (live)
java -jar jenkins-cli.jar -s http://localhost:8080/ console my-job -f

# Get build info
java -jar jenkins-cli.jar -s http://localhost:8080/ get-build my-job 42

# List running builds
java -jar jenkins-cli.jar -s http://localhost:8080/ list-builds

# Get build cause
java -jar jenkins-cli.jar -s http://localhost:8080/ get-build-cause my-job 42
```

### Managing Builds

```bash
# Stop a running build
java -jar jenkins-cli.jar -s http://localhost:8080/ stop-build my-job 42

# Abort a build
java -jar jenkins-cli.jar -s http://localhost:8080/ abort-build my-job 42

# Retry a build
java -jar jenkins-cli.jar -s http://localhost:8080/ replay my-job 42

# Delete a build
java -jar jenkins-cli.jar -s http://localhost:8080/ delete-builds my-job

# Keep build forever
java -jar jenkins-cli.jar -s http://localhost:8080/ keep-build my-job 42

# Get build artifacts
java -jar jenkins-cli.jar -s http://localhost:8080/ get-artifact my-job/42/artifact/path/file.jar

# Archive artifacts
java -jar jenkins-cli.jar -s http://localhost:8080/ copy-artifacts my-job --pattern "*.jar"
```

### Using Cron/Schedules

```bash
# View build schedules
java -jar jenkins-cli.jar -s http://localhost:8080/ list-schedules

# Add build trigger
# (via job configuration XML)
```

---

## Node/Agent Management

### Listing Nodes

```bash
# List all nodes
java -jar jenkins-cli.jar -s http://localhost:8080/ list-nodes

# List online nodes
java -jar jenkins-cli.jar -s http://localhost:8080/ list-nodes | grep -v "offline"

# Get node info
java -jar jenkins-cli.jar -s http://localhost:8080/ get-node my-agent

# Get node configuration
java -jar jenkins-cli.jar -s http://localhost:8080/ get-node my-agent > node.xml
```

### Managing Nodes

```bash
# Create a new node
java -jar jenkins-cli.jar -s http://localhost:8080/ create-node my-new-agent < node.xml

# Update node configuration
java -jar jenenkins-cli.jar -s http://localhost:8080/ update-node my-agent < new-node.xml

# Delete a node
java -jar jenkins-cli.jar -s http://localhost:8080/ delete-node my-agent

# Enable a node
java -jar jenkins-cli.jar -s http://localhost:8080/ enable-node my-agent

# Disable a node
java -jar jenkins-cli.jar -s http://localhost:8080/ disable-node my-agent

# Temporarily offline a node
java -jar jenkins-cli.jar -s http://localhost:8080/ offline-node my-agent "Maintenance reason"

# Bring node back online
java -jar jenkins-cli.jar -s http://localhost:8080/ online-node my-agent
```

### Common Node Operations

```bash
# Check disk usage on node
java -jar jenkins-cli.jar -s http://localhost:8080/ node-monitors my-agent

# Get executor information
java -jar jenkins-cli.jar -s http://localhost:8080/ get-executors my-agent

# Clear workspace on node
java -jar jenkins-cli.jar -s http://localhost:8080/ clear-workspace my-agent
```

---

## Plugin Management

### Listing Plugins

```bash
# List installed plugins
java -jar jenkins-cli.jar -s http://localhost:8080/ list-plugins

# List plugins with updates
java -jar jenkins-cli.jar -s http://localhost:8080/ list-plugins | grep -i "update"

# Get plugin info
java -jar jenkins-cli.jar -s http://localhost:8080/ plugin-info blueocean

# List all available plugins (via API)
curl -s http://localhost:8080/pluginManager/api/json?tree=plugins[shortName,version,hasUpdate] | jq '.plugins[] | select(.hasUpdate==true)'
```

### Installing Plugins

```bash
# Install plugin from center
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin blueocean

# Install plugin from file
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin /path/to/plugin.hpi

# Install plugin from URL
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin https://updates.jenkins.io/latest/blueocean.hpi

# Install plugin (non-interactive)
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin git --username user --password token
```

### Managing Plugins

```bash
# Disable a plugin
java -jar jenkins-cli.jar -s http://localhost:8080/ disable-plugin blueocean

# Enable a plugin
java -jar jenkins-cli.jar -s http://localhost:8080/ enable-plugin blueocean

# Uninstall a plugin
java -jar jenkins-cli.jar -s http://localhost:8080/ uninstall-plugin blueocean

# Restart after plugin install
java -jar jenkins-cli.jar -s http://localhost:8080/ safe-restart

# Reload configuration
java -jar jenkins-cli.jar -s http://localhost:8080/ reload-configuration
```

---

## Credential Management

### Listing Credentials

```bash
# List credentials (via API)
curl -s -u user:token http://localhost:8080/credentials/api/json?tree=credentials[type,id,username,description] | jq .

# List credentials for specific domain
curl -s -u user:token http://localhost:8080/credentials/store/system/domain/_/api/json | jq .
```

### Managing Credentials

```bash
# Add username/password credential
java -jar jenkins-cli.jar -s http://localhost:8080/ add-credentials system "Global" "my-credential-id" "username" "password" "Description"

# Add SSH credential
java -jar jenkins-cli.jar -s http://localhost:8080/ add-credentials system "Global" "ssh-key" "ssh-user" "" "" "Description" --username-key=username --private-key-path=/path/to/key

# Update credential
# (Requires XML configuration)

# Delete credential
java -jar jenkins-cli.jar -s http://localhost:8080/ remove-credentials system "my-credential-id"
```

### Using Credentials in Scripts

```bash
# WithCredentials in Pipeline
withCredentials([usernamePassword(credentialsId: 'my-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
    sh 'echo $USER:$PASS'
}

# Using withEnv
withEnv(["MY_CREDS=${credentials('my-creds')}"]) {
    sh 'echo $MY_CREDS'
}
```

---

## Pipeline Commands

### Declarative Pipeline Basics

```groovy
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'make build'
            }
        }
        stage('Test') {
            steps {
                sh 'make test'
            }
        }
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh 'make deploy'
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

### Scripted Pipeline

```groovy
node {
    stage('Checkout') {
        checkout scm
    }
    stage('Build') {
        sh 'make build'
    }
    stage('Test') {
        try {
            sh 'make test'
        } catch (Exception e) {
            unstable('Tests failed')
        }
    }
    stage('Deploy') {
        if (env.BRANCH_NAME == 'main') {
            sh 'make deploy'
        }
    }
}
```

### Common Pipeline Steps

```groovy
// File operations
writeFile file: 'output.txt', text: 'Hello'
readFile file: 'input.txt'
fileExists file: 'test.txt'

// String operations
sh 'echo ${env.BUILD_NUMBER}'
env.getProperty('MY_VAR')

// Timeout and retry
timeout(time: 30, unit: 'MINUTES') {
    sh 'make build'
}
retry(3) {
    sh 'make build'
}

// Conditional execution
if (env.BRANCH_NAME == 'main') {
    sh 'deploy.sh'
}

// Parallel execution
parallel(
    'Unit Tests': { sh 'make unit-test' },
    'Integration Tests': { sh 'make integration-test' }
)

// Archive artifacts
archiveArtifacts artifacts: 'build/**/*.jar', fingerprint: true

// Publish HTML reports
publishHTML target: [
    allowMissing: false,
    alwaysLinkToLastBuild: true,
    keepAll: true,
    reportDir: 'reports',
    reportFiles: 'index.html',
    reportName: 'Test Report'
]

// JUnit test results
junit '**/test-results/*.xml'

// Send notifications
emailext subject: "Build ${env.JOB_NAME} #${env.BUILD_NUMBER}",
         body: "Check console output at ${env.BUILD_URL}",
         to: 'team@example.com'
```

### Using Shared Libraries

```groovy
// In Jenkinsfile
@Library('my-shared-library') _

myFunction(param1, param2)

// With version
@Library('my-shared-library@1.2.3') _

// Import and use
import com.mycompany.Utils
def utils = new com.mycompany.Utils()
utils.myMethod()
```

---

## System Information

### Getting System Info

```bash
# Get system information
java -jar jenkins-cli.jar -s http://localhost:8080/ system-info

# Get version
java -jar jenkins-cli.jar -s http://localhost:8080/ version

# Get journal (logs)
java -jar jenkins-cli.jar -s http://localhost:8080/ journal

# Get load statistics
curl -s -u user:token http://localhost:8080/loadstatistic/api/json | jq .

# Get queue info
curl -s -u user:token http://localhost:8080/queue/api/json | jq .

# Get overall load
curl -s -u user:token http://localhost:8080/overallLoad/api/json | jq .
```

### Managing System

```bash
# Restart Jenkins
java -jar jenkins-cli.jar -s http://localhost:8080/ restart

# Safe restart (wait for jobs to complete)
java -jar jenkins-cli.jar -s http://localhost:8080/ safe-restart

# Exit Jenkins
java -jar jenkins-cli.jar -s http://localhost:8080/ exit

# Quiet mode (no new builds)
java -jar jenkins-cli.jar -s http://localhost:8080/ quiet-down

# Cancel quiet mode
java -jar jenkins-cli.jar -s http://localhost:8080/ cancel-quiet-down
```

### Logs and Diagnostics

```bash
# Get log (last 100 lines)
java -jar jenkins-cli.jar -s http://localhost:8080/ logger

# Set log level
java -jar jenkins-cli.jar -s http://localhost:8080/ set-log-level FINE

# Get all log recorders
curl -s -u user:token http://localhost:8080/log/record/ | jq .

# View master logs via curl
curl -s -u user:token http://localhost:8080/log/text | tail -n 100
```

---

## User Management

### Listing Users

```bash
# List users
java -jar jenkins-cli.jar -s http://localhost:8080/ list-users

# Get user info
java -jar jenkins-cli.jar -s http://localhost:8080/ get-user username

# Get user details via API
curl -s -u user:token http://localhost:8080/user username/api/json | jq .
```

### Managing Users

```bash
# Create user (via CLI login)
# Note: Users are typically created via UI or security realm

# Add matrix permissions
java -jar jenkins-cli.jar -s http://localhost:8080/ add-job-to-view my-job my-view

# Remove job from view
java -jar jenkins-cli.jar -s http://localhost:8080/ remove-job-from-view my-job my-view
```

---

## View Management

### Creating Views

```bash
# Create a new view
java -jar jenkins-cli.jar -s http://localhost:8080/ create-view my-view < view.xml

# Delete a view
java -jar jenkins-cli.jar -s http://localhost:8080/ delete-view my-view

# Update view
java -jar jenkins-cli.jar -s http://localhost:8080/ update-view my-view < new-view.xml
```

### Managing Views

```bash
# Add job to view
java -jar jenkins-cli.jar -s http://localhost:8080/ add-job-to-view my-job "My View"

# Remove job from view
java -jar jenkins-cli.jar -s http://localhost:8080/ remove-job-from-view my-job "My View"

# Get view config
java -jar jenkins-cli.jar -s http://localhost:8080/ get-view my-view

# List all views
java -jar jenkins-cli.jar -s http://localhost:8080/ list-views
```

---

## Quick Reference

### Essential One-Liners

```bash
# Get Jenkins version
curl -s http://localhost:8080/api/json | jq -r '.version'

# Count total builds
curl -s -u user:token http://localhost:8080/job/my-job/api/json | jq '.lastBuild.number'

# Get build duration
curl -s -u user:token http://localhost:8080/job/my-job/lastBuild/api/json | jq '.duration'

# Check if job is building
curl -s -u user:token http://localhost:8080/job/my-job/api/json | jq '.lastBuild.building'

# Get last successful build
curl -s -u user:token http://localhost:8080/job/my-job/api/json | jq '.lastSuccessfulBuild.number'

# List queued items
curl -s -u user:token http://localhost:8080/queue/api/json | jq '.items[] | {job: .task.name, inQueueSince: .inQueueSince}'

# Get build parameters
curl -s -u user:token http://localhost:8080/job/my-job/lastBuild/api/json | jq '.actions[] | select(._class=="hudson.model.ParametersAction") | .parameters[].name'

# Trigger parameterized build
curl -X POST http://localhost:8080/job/my-job/buildWithParameters \
  -u user:token \
  --data-urlencode PARAM1=value1 \
  --data-urlencode PARAM2=value2

# Download artifact
curl -u user:token -o artifact.jar "http://localhost:8080/job/my-job/42/artifact/path/file.jar"

# Get changes since last build
curl -s -u user:token http://localhost:8080/job/my-job/lastBuild/api/json | jq '[.changeSets[].items[] | {author: .authorEmail, msg: .msg, revision: .commitId}]'
```

---

## Troubleshooting

### Common Issues

```bash
# Job not appearing - check permissions
java -jar jenkins-cli.jar -s http://localhost:8080/ who-am-i

# Authentication failures - check API token
# Generate new token at: /user/{username}/configure

# Build stuck - check queue
curl -s -u user:token http://localhost:8080/queue/api/json | jq '.items'

# Node offline - check agent logs
java -jar jenkins-cli.jar -s http://localhost:8080/ log my-agent

# Plugin not loading - check plugin manager
java -jar jenkins-cli.jar -s http://localhost:8080/ plugin-info plugin-name

# Performance issues - check metrics
curl -s http://localhost:8080/metrics/your-api-key/metrics | jq '.gauges'
```

### Health Checks

```bash
# Check disk space
java -jar jenkins-cli.jar -s http://localhost:8080/ system-information | grep -i disk

# Check executor utilization
java -jar jenkins-cli.jar -s http://localhost:8080/ execute-script "println(Jenkins.instance.toComputer().findAll { it.executors.size() > 0 }.collect { [it.displayName, it.executors.collect { it.isBusy() }] })"

# Check heap memory
java -jar jenkins-cli.jar -s http://localhost:8080/ execute-script "println(Runtime.getRuntime().freeMemory())"
```

---

## References

- [Jenkins CLI Documentation](https://www.jenkins.io/doc/book/managing/cli/)
- [Jenkins Pipeline Steps](https://www.jenkins.io/doc/pipeline/steps/)
- [Jenkins API Documentation](https://www.jenkins.io/doc/book/using/remote-access-api/)
- [Jenkins Pipeline Best Practices](https://www.jenkins.io/doc/book/pipeline/pipeline-best-practices/)
