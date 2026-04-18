# Jenkins Troubleshooting Guide

## Purpose

This guide helps operators diagnose and resolve common failures encountered during Jenkins controller and agent operation, including startup failures, plugin issues, build failures, and connectivity problems. It provides step-by-step diagnostic procedures and resolution steps for production Jenkins environments.

## When to use

- Jenkins controller fails to start after a restart or upgrade
- Agent nodes fail to connect or go offline unexpectedly
- Builds fail with cryptic error messages
- Plugin installation or updates cause unexpected behavior
- Pipeline executions stall or timeout
- Jenkins UI becomes unresponsive or displays errors

## Prerequisites

- Jenkins controller running on Linux/Windows
- Administrative access to Jenkins controller filesystem
- Network access to Jenkins UI (default port 8080)
- JRE/JDK installed (Java 11 or later recommended)
- For agent issues: SSH or JNLP access to agent nodes

## Steps

### 1. Verify Java runtime

Check that Java is installed and the correct version is being used:

```bash
java -version
echo $JAVA_HOME
```

Common issues:
- Java not installed: install with `apt-get install openjdk-11-jdk` or `yum install java-11-openjdk`
- Multiple Java versions: use `update-alternatives --config java` to select
- JAVA_HOME not set: add to `/etc/environment` or profile

### 2. Check Jenkins service status

On systemd-based systems:

```bash
systemctl status jenkins
journalctl -u jenkins -n 50 --no-pager
```

On init.d systems:

```bash
service jenkins status
cat /var/log/jenkins/jenkins.log | tail -100
```

### 3. Inspect JENKINS_HOME directory

Verify JENKINS_HOME is accessible and has correct permissions:

```bash
ls -la $JENKINS_HOME
df -h $JENKINS_HOME
```

Common issues:
- Disk space exhausted: `df -h` shows 100% usage — clean old build records
- Permission denied: fix with `chown -R jenkins:jenkins $JENKINS_HOME`
- Corrupted configuration: check `$JENKINS_HOME/config.xml` for XML validation errors

### 4. Diagnose plugin failures

Check plugin status from UI: Manage Jenkins → Manage Plugins → Advanced

To check from CLI:

```bash
curl -s http://localhost:8080/pluginManager/api/json | jq '.plugins[] | select(.enabled==false)'
```

Common plugin issues:
- Plugin failed to load: check `$JENKINS_HOME/plugins/*.jpi.err` files
- Dependency missing: review plugin dependencies in UI
- Version conflict: downgrade or upgrade conflicting plugins

To recover from broken plugins:

```bash
# Disable plugin by renaming
cd $JENKINS_HOME/plugins
mv problematic-plugin.jpi problematic-plugin.jpi.disabled
systemctl restart jenkins
```

### 5. Identify build failures

Check build console output from UI or filesystem:

```bash
ls -la $JENKINS_HOME/jobs/*/builds/*
cat $JENKINS_HOME/jobs/<job-name>/builds/<build-number>/log
```

Common build failure patterns:
- `Exit code 127`: command not found — ensure tool is installed on agent
- `Exit code 137`: OOM killer — increase Jenkins master/agent memory
- `Permission denied`: check agent workspace permissions
- `Connection refused`: agent lost connectivity — review agent logs

### 6. Troubleshoot agent connectivity

For SSH agents:

```bash
# Check agent status
curl -s http://localhost:8080/computer/api/json | jq '.computer[] | {displayName, offline}'

# Check SSH connectivity from controller
ssh -v <agent-host> "echo test"
```

For JNLP agents:

```bash
# Check JNLP port (default 50000)
netstat -tlnp | grep 50000
```

Agent offline causes:
- Agent process terminated: restart agent with `java -jar agent.jar`
- Firewall blocking JNLP port: open port 50000
- Certificate expired: re-enable agent from UI

### 7. Review system logs

```bash
# Controller logs
tail -f $JENKINS_HOME/jenkins.log

# Audit logs (if enabled)
ls -la $JENKINS_HOME/audit/

# Agent logs on agent machine
ls -la ~/jenkins/logs/
```

### 8. Check resource utilization

```bash
# CPU and memory
top -b -n 1 | head -20
free -h

# Open file descriptors
cat /proc/sys/fs/file-nr

# Java heap usage via JMX
jcmd <pid> GC.heap_info
```

## Verify

After applying fixes, verify Jenkins is operational:

1. Access UI: `http://localhost:8080` loads without errors
2. Check system information: Manage Jenkins → System Information shows all properties
3. Test agent connectivity: Nodes appear online and respond to commands
4. Run a test job: Execute a simple freestyle job to confirm builds work
5. Check queue: Build queue processes without stall

## Rollback

If a change causes issues:

1. **Plugin update rollback**: Disable updated plugins and revert to previous versions from `$JENKINS_HOME/plugins/`
2. **Configuration rollback**: Restore `$JENKINS_HOME/config.xml` from backup
3. **Java version rollback**: Revert JAVA_HOME to previous version
4. **Full rollback**: Restore entire JENKINS_HOME from backup tarball

```bash
# Stop Jenkins first
systemctl stop jenkins

# Rollback config
cp $JENKINS_HOME/config.xml $JENKINS_HOME/config.xml.broken
tar -xzf /backup/jenkins-home-$(date +%Y-%m-%d).tar.gz -C /

# Restart
systemctl start jenkins
```

## Common errors

| Error message | Root cause | Solution |
|---|---|---|
| `java.io.IOException: Not enough space` | Disk full on build node | Clean workspace, increase disk, add node |
| `Permission denied: publickey` | SSH key mismatch between controller and agent | Regenerate SSH keys, add to authorized_keys |
| `Connection refused (connect refused)` | JNLP port blocked or agent not running | Open firewall port, restart agent service |
| `503 Service Unavailable` | Jenkins overloaded or restarting | Wait, check memory, increase heap |
| `Connection reset by peer` | Agent timeout, network interruption | Increase agent connection timeout |
| `org.apache.commons.jelly.JellyException` | Plugin incompatible with Jenkins version | Downgrade plugin or upgrade Jenkins |
| `Failed to connect to repository` | Git credentials expired or permission denied | Update credentials in Jenkins credentials store |
| `java.lang.OutOfMemoryError: Java heap space` | Insufficient JVM heap | Increase -Xmx in startup configuration |

## References

- Jenkins Troubleshooting Official: https://www.jenkins.io/doc/book/troubleshooting/
- Jenkins Wiki Troubleshooting: https://wiki.jenkins-ci.org/display/JENKINS/Troubleshooting
- Common Build Failures: https://www.jenkins.io/doc/book/pipeline/troubleshooting/
- Jenkins GitHub Issues: https://github.com/jenkinsci/jenkins/issues
- Stack Overflow Jenkins Tag: https://stackoverflow.com/questions/tagged/jenkins