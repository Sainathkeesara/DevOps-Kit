# GitHub Webhook Setup with Jenkins

## Purpose

This document describes how to configure GitHub webhooks to trigger Jenkins pipeline builds on code changes. This enables automated CI/CD workflows where push events to a repository automatically start Jenkins jobs.

## When to use

Configure GitHub webhooks with Jenkins when you need:
- Automated builds on every push to any branch
- Trigger builds on pull request events (opened, updated, closed)
- Branch-specific build triggers
- Build notifications sent back to GitHub via commit status

Do **not** use webhooks if you only need manual build triggers or scheduled builds.

## Prerequisites

- Jenkins 2.x installed and accessible via HTTP/HTTPS
- GitHub repository admin access (or owner permission) to configure webhooks
- Jenkins GitHub Integration plugin installed (git-plugin, github-branch-source-plugin)
- GitHub personal access token with `repo` scope (for repository access)
- Jenkins credentials configured for GitHub API access

## Steps

### Step 1: Install Required Jenkins Plugins

Install these plugins via Jenkins Manage Plugins:

1. **GitHub plugin** - Core GitHub integration
2. **GitHub Branch Source Plugin** - Multi-branch pipeline support
3. **Pipeline: GitHub Groovy Libraries** - GitHub-specific pipeline steps

Verify installation:
```bash
# Check plugin status via Jenkins CLI or UI
# Navigate to: Manage Jenkins > Manage Plugins > Installed
```

### Step 2: Configure GitHub Credentials in Jenkins

1. Navigate to **Manage Jenkins > Credentials > Add Credentials**
2. Select **Kind: Username with password**
3. Fill in:
   - **Username**: GitHub username
   - **Password**: GitHub personal access token
   - **ID**: `github-credentials` (or descriptive name)
   - **Description**: GitHub API access
4. Click **OK**

To create a personal access token:
1. Go to GitHub > Settings > Developer settings > Personal access tokens > Tokens (classic)
2. Click **Generate new token (classic)**
3. Select scopes: `repo` (full control), `admin:repo_hook` (if managing webhooks)
4. Copy the token immediately (won't be shown again)

### Step 3: Configure GitHub Server in Jenkins

1. Navigate to **Manage Jenkins > System**
2. Find **GitHub** section
3. Click **Add GitHub Server**
4. Configure:
   - **Name**: `GitHub`
   - **API URL**: `https://api.github.com` (default)
   - **Credentials**: Select the credentials created in Step 2
5. Click **Test Connection** to verify
6. Click **Save**

### Step 4: Create Jenkins Pipeline with GitHub Triggers

Create a pipeline job with GitHub webhook trigger:

```groovy
pipeline {
    agent any
    
    triggers {
        GitHubPushTrigger()
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'make build'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'make test'
            }
        }
    }
    
    post {
        success {
            echo 'Build succeeded!'
        }
        failure {
            echo 'Build failed!'
        }
    }
}
```

Or for declarative pipelines using GitHub Branch Sources:

```groovy
pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 1, unit: 'HOURS')
    }
    
    stages {
        stage('Build') {
            steps {
                echo "Building branch ${env.GIT_BRANCH}"
            }
        }
    }
}
```

Configure in job UI:
1. **General**: Check "GitHub project" and enter project URL
2. **Build Triggers**: Check "GitHub hook trigger for GITScm polling"
3. **Pipeline**: Select Definition "Pipeline script" or "Pipeline script from SCM"

### Step 5: Configure Webhook in GitHub Repository

1. Navigate to your GitHub repository
2. Go to **Settings > Webhooks > Add webhook**
3. Configure:
   - **Payload URL**: `https://<jenkins-url>/github-webhook/`
     - Example: `https://jenkins.example.com/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: (optional) Set a secret for payload verification
   - **Events**: Select "Just the push event" or customize:
     - Pushes
     - Pull requests
     - Workflow runs
4. Click **Add webhook**

### Step 6: Enable Webhook in Jenkins Job

For each job that should respond to webhooks:

1. Open job configuration
2. Under **Build Triggers**, check:
   - **GitHub hook trigger for GITScm polling**
3. Save the configuration

## Verify

### Test Webhook Delivery

1. In GitHub webhook settings, find your webhook
2. Click **Edit** > **Recent Deliveries**
3. Click **Redeliver** on a recent delivery
4. Check response status (200 = success)

### Verify Jenkins Build Triggered

1. Make a small change and push to the repository
2. Check Jenkins job page - a new build should start within seconds
3. Build should appear in **Build History** with cause "GitHub Hook"

### Check GitHub Commit Status

After build completes, check GitHub:
1. Navigate to the commit in GitHub
2. Commit status should show Jenkins results (if configured with GitHub Status API)

## Rollback

### Remove Webhook

To disable webhook triggering:

**Via GitHub UI:**
1. Repository > Settings > Webhooks
2. Delete the webhook

**Via GitHub API:**
```bash
curl -X DELETE \
  -H "Authorization: token <TOKEN>" \
  https://api.github.com/repos/<owner>/<repo>/hooks/<hook-id>
```

### Remove GitHub Credentials

1. Jenkins > Manage Jenkins > Credentials
2. Delete the GitHub credentials

### Disable Triggers in Job

1. Job configuration > Build Triggers
2. Uncheck "GitHub hook trigger for GITScm polling"

## Common errors

| Error | Cause | Fix |
|-------|-------|-----|
| 404 on webhook delivery | Incorrect payload URL | Verify Jenkins URL is correct and accessible |
| 403 forbidden | Token lacks permissions | Ensure token has `repo` scope |
| Hook not triggered | Webhook disabled in job | Check "GitHub hook trigger" in job config |
| Duplicate builds | Multiple webhook sources | Check for duplicate webhooks or polling |
| Hook timeout | Jenkins unresponsive | Check Jenkins is running and accessible |
| Credential test fails | Invalid token | Regenerate token and update credentials |
| Job not found | Incorrect project URL | Verify GitHub project URL in job config |

### Debugging Tips

1. Check Jenkins system log:
   ```bash
   tail -f /var/log/jenkins/jenkins.log
   ```

2. Enable debug logging:
   - Manage Jenkins > System Log > Add new log recorder
   - Add: `org.jenkinsci.plugins.github`

3. Verify GitHub connection:
   - Manage Jenkins > System > GitHub > Test Connection

## References

- Jenkins GitHub Plugin — https://plugins.jenkins.io/github/ (verified: 2026-03-09)
- GitHub Webhooks Docs — https://docs.github.com/en/webhooks (verified: 2026-03-09)
- Jenkins Credentials — https://www.jenkins.io/doc/book/using/using-credentials/ (verified: 2026-03-09)
- GitHub Personal Access Tokens — https://github.com/settings/tokens (verified: 2026-03-09)
