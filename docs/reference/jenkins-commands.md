# Jenkins CLI Commands Reference

## Purpose

This reference provides 50+ practical Jenkins CLI commands for day-to-day operations, automation, and scripting. Commands are organized by category and include real-world examples that can be executed in production Jenkins environments.

## When to use

- Writing Jenkins automation scripts
- Troubleshooting build and pipeline issues
- Managing jobs, builds, and agents via CLI
- Integrating Jenkins with external tools
- Performing bulk operations on jobs

## Prerequisites

- Jenkins controller running (Linux/Windows)
- `jenkins-cli.jar` or `jenkins` CLI tool installed
- Jenkins user with appropriate permissions
- API token configured (for REST/CLI authentication)

## CLI Access Methods

### Via JAR (legacy)
```bash
wget http://localhost:8080/jnlpJars/jenkins-cli.jar
java -jar jenkins-cli.jar -s http://localhost:8080/whoami
```

### Via REST API (recommended)
```bash
# With API token
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_TOKEN="abc123def456"

# Get version
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" "$JENKINS_URL/api/json"
```

### Via Jenkins CLI (modern)
```bash
# Download CLI
curl -s -o jenkins http://localhost:8080/jenkins/cli
chmod +x jenkins
./jenkins -s http://localhost:8080 who-am-i
```

---

## Job Management Commands

### List all jobs
```bash
# Via REST
curl -s -u "$USER:$TOKEN" "$URL/api/json?tree=jobs[name]" | jq '.jobs[].name'

# Via CLI
java -jar jenkins-cli.jar -s $URL list-jobs

# Get job config
curl -s -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/config.xml"

# Get job description
curl -s -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/api/json?tree=description"
```

### Create job from XML
```bash
# Via REST
curl -s -X POST -u "$USER:$TOKEN" \
  --data-binary @config.xml \
  -H "Content-Type: application/xml" \
  "$URL/createItem?name=$JOB_NAME"

# Via CLI
java -jar jenkins-cli.jar -s $URL create-job newjob < config.xml
```

### Copy job
```bash
# Via REST
curl -s -X POST -u "$USER:$TOKEN" \
  "$URL/createItem?name=newjob&mode=copy&from=existingjob"

# Via CLI
java -jar jenkins-cli.jar -s $URL copy-job existingjob newjob
```

### Delete job
```bash
# Via REST (must disable first)
curl -s -X POST -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/disable"
curl -s -X POST -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/doDelete"

# Via CLI
java -jar jenkins-cli.jar -s $URL delete-job $JOB_NAME
```

### Enable/Disable job
```bash
# Disable
curl -s -X POST -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/disable"

# Enable
curl -s -X POST -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/enable"
```

---

## Build Commands

### Trigger build
```bash
# Basic build
curl -s -X POST -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/build"

# With parameters
curl -s -X POST -u "$USER:$TOKEN" \
  --data-urlencode "PARAM1=value1" \
  --data-urlencode "PARAM2=value2" \
  "$URL/job/$JOB_NAME/buildWithParameters"

# Queue build
curl -s -X POST -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/build"
```

### Get build status
```bash
# Build info
curl -s -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/lastBuild/api/json"

# All builds
curl -s -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/api/json?tree=builds[number,result,timestamp]"

# Build console output
curl -s -u "$USER:$TOKEN" "$URL/job/$JOB_NAME/$BUILD_NUMBER/console"
```

### Stop build
```bash
# Stop running build
curl -s -X POST -u "$USER:$TOKEN" \
  "$URL/job/$JOB_NAME/$BUILD_NUMBER/stop"
```

### Get build parameters
```bash
# Parameters used
curl -s -u "$USER:$TOKEN" \
  "$URL/job/$JOB_NAME/$BUILD_NUMBER/api/json?tree=actions[parameters]"
```

---

## Agent/Node Management

### List agents
```bash
# All agents
curl -s -u "$USER:$TOKEN" "$URL/computer/api/json"

# Agent info
curl -s -u "$USER:$TOKEN" "$URL/computer/$NODE_NAME/api/json"
```

### Agent online/offline
```bash
# Take offline with cause
curl -s -X POST -u "$USER:$TOKEN" \
  --data-urlencode "offline=true&offlineCause=Maintenance" \
  "$URL/computer/$NODE_NAME/toggleOffline"

# Bring online
curl -s -X POST -u "$USER:$TOKEN" \
  "$URL/computer/$NODE_NAME/toggleOffline"
```

### Delete agent
```bash
curl -s -X POST -u "$USER:$TOKEN" \
  "$URL/computer/$NODE_NAME/doDelete"
```

---

## User and Permissions

### List users
```bash
curl -s -u "$USER:$TOKEN" "$URL/api/json?tree=users[name]"
```

### Get user info
```bash
curl -s -u "$USER:$TOKEN" "$URL/user/$USERNAME/api/json"
```

### Get current user
```bash
curl -s -u "$USER:$TOKEN" "$URL/api/json?tree=user[name]"
```

---

## Queue Management

### List queued builds
```bash
# Queue info
curl -s -u "$USER:$TOKEN" "$URL/queue/api/json"

# Queue items with why
curl -s -u "$USER:$TOKEN" \
  "$URL/queue/api/json?tree=items[why,tasks[name]]"
```

### Cancel queued build
```bash
curl -s -X POST -u "$USER:$TOKEN" \
  "$URL/queue/item/$QUEUE_ID/cancelQueue"
```

---

## Plugin Management

### List plugins
```bash
# All plugins
curl -s -u "$USER:$TOKEN" "$URL/pluginManager/api/json?tree=plugins[shortName,version,enabled]"

# Search for plugin
curl -s -u "$USER:$TOKEN" \
  "$URL/pluginManager/api/json?tree=plugins[shortName]" | \
  jq '.plugins[] | select(.shortName == "git")'
```

### Install plugin
```bash
# Download and install (requires restart)
curl -s -X POST -u "$USER:$TOKEN" \
  "$URL/pluginManager/installNecessaryPlugins?json={'plugins':[{'name':'git'}]}"
```

### Disable plugin
```bash
curl -s -X POST -u "$USER:$TOKEN" \
  "$URL/pluginManager/$PLUGIN_NAME/disable"
```

---

## Credential Management

### List credentials
```bash
# Domain credentials
curl -s -u "$USER:$TOKEN" \
  "$URL/credentials/domain/system/api/json"
```

### Add credential (username/password)
```bash
curl -s -X POST -u "$USER:$TOKEN" \
  -d '{
    "credentials": {
      "scope": "GLOBAL",
      "id": "new-creds",
      "username": "deploy",
      "password": "secret",
      "description": "Deployment credential"
    }
  }' \
  "$URL/credentials/store/system/domain/_/createCredentials"
```

---

## System Information

### Get Jenkins info
```bash
# System info
curl -s -u "$USER:$TOKEN" "$URL/api/json"

# JVM info
curl -s -u "$USER:$TOKEN" "$URL/api/json?tree=systemInfo[*]"

# Queue info
curl -s -u "$USER:$TOKEN" "$URL/queue/api/json"

# View configuration
curl -s -u "$USER:$TOKEN" "$URL/configure"
```

---

## View Management

### List views
```bash
curl -s -u "$USER:$TOKEN" "$URL/api/json?tree=views[name]"
```

### Create view
```bash
curl -s -X POST -u "$USER:$TOKEN" \
  --data-urlencode "name=MyView" \
  --data-urlencode "mode=list" \
  "$URL/createView"
```

---

## Folder Management (CloudBees)

### Create folder
```bash
curl -s -X POST -u "$USER:$TOKEN" \
  -H "Content-Type: application/xml" \
  --data-binary @folder-config.xml \
  "$URL/createItem?name=MyFolder&mode=com.cloudbees.hudson.plugins.folder.Folder"
```

---

## Pipeline Commands

### Get pipeline runs
```bash
curl -s -u "$USER:$TOKEN" \
  "$URL/job/$PIPELINE_JOB/api/json?tree=builds[number,result,changeSets]"
```

### Get pipeline stages
```bash
curl -s -u "$USER:$TOKEN" \
  "$URL/job/$PIPELINE_JOB/$BUILD_NUMBER/wfapi/describe"
```

---

## Script Console

### Run Groovy script
```bash
# Via REST
curl -s -X POST -u "$USER:$TOKEN" \
  --data-urlencode "script=println(Jenkins.instance.version)" \
  "$URL/script"

# Via CLI
java -jar jenkins-cli.jar -s $URL groovy --script=script.groovy
```

### Example scripts
```bash
# List all jobs
curl -s -X POST -u "$USER:$TOKEN" \
  --data-urlencode "script=Jenkins.instance.items.each{println it.fullName}" \
  "$URL/script"

# List running builds
curl -s -X POST -u "$USER:$TOKEN" \
  --data-urlencode "script=Jenkins.instance.queue.items.each{println it.task.name}" \
  "$URL/script"

# Get JVM memory
curl -s -X POST -u "$USER:$TOKEN" \
  --data-urlencode "script=Runtime.runtime.totalMemory()" \
  "$URL/script"
```

---

## Quiet Down and Restart

### Quiet down (prepare for restart)
```bash
curl -s -X POST -u "$USER:$TOKEN" "$URL/quietDown"
```

### Cancel quiet down
```bash
curl -s -X POST -u "$USER:$TOKEN" "$URL/cancelQuietDown"
```

### Safe restart
```bash
curl -s -X POST -u "$USER:$TOKEN" "$URL/safeRestart"
```

### Safe exit (prepare for shutdown)
```bash
curl -s -X POST -u "$USER:$TOKEN" "$URL/safeExit"
```

---

## References

- Jenkins CLI Documentation: https://www.jenkins.io/doc/book/managing/cli/
- Jenkins REST API: https://www.jenkins.io/doc/book/using/remote-access-api/
- Jenkins Script Console: https://www.jenkins.io/doc/book/managing/script-console/
- Jenkins Remote API Examples: https://github.com/jenkinsci/jenkins-cli-ruby-plugin/wiki/Examples
- Jenkins Pipeline Steps Reference: https://www.jenkins.io/doc/pipeline/steps/