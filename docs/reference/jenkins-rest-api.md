# Jenkins REST API Commands

## Purpose

This reference provides common Jenkins REST API calls for automation. These commands enable programmatic interaction with Jenkins for job management, build triggers, queue control, agent management, and plugin operations.

## When to use

- Scripting automated CI/CD pipelines
- Integrating Jenkins with external systems
- Bulk job management and configuration
- Monitoring build status from external tools
- Triggering builds from webhooks or scheduling systems

## Prerequisites

- Jenkins 2.0 or later
- Valid Jenkins user credentials or API token
- Network access to Jenkins server
- curl or wget for HTTP calls
- jq for JSON parsing (optional but recommended)

## Steps

### Authentication

Jenkins REST API supports multiple authentication methods:

```bash
# Using username and API token (recommended)
JENKINS_USER="admin"
JENKINS_TOKEN="your-api-token-here"
JENKINS_URL="http://jenkins.example.com"

# Create Basic Auth header
AUTH_HEADER=$(echo -n "$JENKINS_USER:$JENKINS_TOKEN" | base64)
```

### Job Management

```bash
# List all jobs
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/api/json?tree=jobs[name,url,color]" | jq '.jobs[]'

# Get job configuration (XML)
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/config.xml"

# Create new job from XML
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/createItem?name=new-job" \
  -H "Content-Type: application/xml" \
  --data @job-config.xml

# Update job configuration
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/config.xml" \
  -H "Content-Type: application/xml" \
  --data @updated-config.xml

# Copy job
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/createItem?name=new-job&mode=copy&from=source-job"

# Delete job
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/doDelete"

# Enable job
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/enable"

# Disable job
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/disable"
```

### Build Triggers

```bash
# Trigger build (no parameters)
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/build"

# Trigger build with parameters
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/buildWithParameters" \
  -d "PARAM1=value1&PARAM2=value2"

# Trigger parameterized build via API token
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/build" \
  -H "Jenkins-Crumb: $(curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
    "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumb')"

# Queue build with delay
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/build" \
  -H "Jenkins-Auth: Basic $AUTH_HEADER" \
  -H "X-Trigger-Token: $(curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
    "$JENKINS_URL/queue/item/{id}/api/json" | jq -r '.actions[].token')"

# Get last build number
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/lastBuild/buildNumber"

# Get next build number
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/nextBuildNumber"
```

### Build Information

```bash
# Get build information
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/{build-number}/api/json" | jq '.'

# Get last successful build
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/lastSuccessfulBuild/api/json" | jq '.'

# Get last failed build
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/lastFailedBuild/api/json" | jq '.'

# Get last stable build
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/lastStableBuild/api/json" | jq '.'

# Get build console output
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/{build-number}/consoleText"

# Get build changes (commits)
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/{build-number}/changes" | jq '.changes[]'

# Get build artifacts
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/{build-number}/api/json" | jq '.artifacts[]'

# Download specific artifact
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -o artifact.jar \
  "$JENKINS_URL/job/job-name/{build-number}/artifact/path/to/artifact.jar"

# Stop a running build
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/{build-number}/stop"

# Terminate a build
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/{build-number}/term"

# Get build timestamps
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/{build-number}/api/json" | \
  jq '{duration: .duration, timestamp: .timestamp, result: .result}'
```

### Queue Management

```bash
# Get queue information
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/queue/api/json" | jq '.items[]'

# Get queue item details
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/queue/item/{queue-id}/api/json" | jq '.'

# Cancel queue item
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/queue/item/{queue-id}/cancelQueue"

# Get queue length
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/queue/api/json" | jq '.items | length'
```

### Agent Management

```bash
# List all agents
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/computer/api/json" | jq '.computers[]'

# Get specific agent info
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/computer/agent-name/api/json" | jq '.'

# Get agent configuration
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/computer/agent-name/config.xml"

# Disable agent
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/computer/agent-name/disable"

# Enable agent
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/computer/agent-name/enable"

# Delete agent
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/computer/agent-name/doDelete"

# Take agent offline
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/computer/agent-name/toggleOffline"

# Get agent system info
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/computer/agent-name/systemInfo" | jq '.'
```

### Plugin Management

```bash
# List installed plugins
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/pluginManager/api/json" | jq '.plugins[]'

# Get plugin info
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/pluginManager/plugin/plugin-name/api/json" | jq '.'

# Install plugin (upload)
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/pluginManager/uploadPlugin" \
  -H "enctype: multipart/form-data" \
  -F "pluginFile=@plugin.hpi"

# Enable plugin
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/pluginManager/plugin/plugin-name/enable"

# Disable plugin
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/pluginManager/plugin/plugin-name/disable"
```

### User Management

```bash
# List users
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/user/api/json" | jq '.users[]'

# Get user info
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/user/username/api/json" | jq '.'

# Create user
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/createUser" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=newuser&password=password&fullname=Full+Name&email=email@example.com"
```

### View Management

```bash
# List views
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/api/json?tree=views[name]" | jq '.views[]'

# Create view
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/createView?name=new-view"

# Get view config
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/view/view-name/config.xml"

# Add job to view
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/view/view-name/addJobToView?name=job-name"

# Remove job from view
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/view/view-name/removeJobFromView?name=job-name"
```

### Security

```bash
# Get CSRF crumb
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/crumbIssuer/api/json" | jq -r '.crumb'

# Check API token
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/api/json"

# Get security config
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/api/json?tree=securityRealm,authorizationStrategy"

# Get build permissions
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/api/json" | jq '.builds[] | select(.number == 1) | .actions'
```

### System Information

```bash
# Get Jenkins system info
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/systemInfo" | head -20

# Get overall load
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/loadInfo/api/json" | jq '.'

# Get statistics
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/overallLoad/api/json" | jq '.'

# Get metric data
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/metrics/currentMetrics" | jq '.'
```

### Pipeline Jobs

```bash
# Get pipeline definition
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/pipeline-name/definition/cps2Definition/script"

# Get pipeline stages
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/pipeline-name/{build-number}/wfapi/describe" | jq '.stages[]'

# Get pipeline node details
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/pipeline-name/{build-number}/wfapi/describe" | jq '.nodes[]'

# Replay pipeline
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/pipeline-name/{build-number}/replay"

# Get Blue Ocean pipeline data
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/blue/rest/organizations/jenkins/pipelines/job-name/runs" | jq '.'
```

## Verify

### Test API Access

```bash
# Simple health check
curl -s -o /dev/null -w "%{http_code}" \
  -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/api/json"

# Should return 200 if authenticated correctly
```

### Verify Job Exists

```bash
# Check if job exists
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/api/json" | jq -e '.name' > /dev/null 2>&1 \
  && echo "Job exists" || echo "Job not found"
```

### Check Build Status

```bash
# Get last build result
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  "$JENKINS_URL/job/job-name/lastBuild/api/json" | jq -r '.result // "IN_PROGRESS"'
```

## Rollback

### Revert Job Configuration

```bash
# Restore from backup
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/config.xml" \
  -H "Content-Type: application/xml" \
  --data @backup-config.xml
```

### Disable Trigger

```bash
# Temporarily disable builds
curl -s -u "$JENKINS_USER:$JENKINS_TOKEN" \
  -X POST "$JENKINS_URL/job/job-name/disable"
```

## Common Errors

### Error: 401 Unauthorized

**Symptom:** Authentication fails with HTTP 401.

**Solution:** Verify username and API token. Generate API token from Jenkins UI: User → Configure → API Token.

### Error: 403 Forbidden

**Symptom:** Authenticated but access denied.

**Solution:** Check user has Overall/Read and Job/Read permissions. Verify CSRF crumb for POST requests.

### Error: 404 Not Found

**Symptom:** Resource not found.

**Solution:** Verify job name, build number, or URL path is correct. Check for URL encoding issues.

### Error: 405 Method Not Allowed

**Symptom:** HTTP method not supported.

**Solution:** Use correct HTTP method (GET for reads, POST for actions). Some endpoints require POST.

### Error: 422 Unprocessable Entity

**Symptom:** Invalid configuration data.

**Solution:** Validate XML/JSON structure. Check for special characters that need escaping.

## References

- [Jenkins Remote Access API](https://www.jenkins.io/doc/book/using/remote-access-api/) (2026-01-15)
- [REST API Reference](https://javadoc.jenkins.io/hudson/cli/CLICommand.html) (2026-01-15)
- [API Token Documentation](https://www.jenkins.io/doc/book/using/using-credentials/) (2026-01-15)
- [Blue Ocean REST API](https://docs.cloudbees.com/docs/admin-resources/latest/blueocean-rest-api) (2026-01-15)
- [Pipeline REST API](https://www.jenkins.io/doc/book/pipeline/running-pipelines/) (2026-01-15)
