# Jenkinsfile Template for Maven/Gradle Builds

## Purpose

This template provides a reusable Jenkinsfile for Java projects using Maven or Gradle build systems. It implements enterprise-grade practices including artifact management, test reporting, sonarqube integration, and deployment promotion.

## When to use

- Building Java applications with Maven or Gradle
- Creating CI/CD pipelines for Java projects
- Implementing multi-stage promotion (dev → staging → prod)
- Integrating with SonarQube for code quality gates

## Prerequisites

- Jenkins controller with Pipeline plugin installed
- Maven tool configured (or use Maven wrapper in repository)
- Gradle tool configured (or use Gradle wrapper)
- SonarQube server configured in Jenkins (optional)
- Nexus or Artifactory repository for artifact storage (optional)
- Git credentials configured in Jenkins

## Steps

### 1. Configure Jenkins tools

In Jenkins UI: Manage Jenkins → Global Tool Configuration

```groovy
// Maven: Add Maven installation (e.g., Maven 3.9)
// Gradle: Add Gradle installation (e.g., Gradle 8.5)
```

### 2. Add credentials

Manage Jenkins → Credentials → Add:
- Git credentials (username/password or SSH key)
- SonarQube token
- Repository credentials (for deployment)

### 3. Create Jenkinsfile in project repository

Add this Jenkinsfile to your project root:

```groovy
pipeline {
    agent {
        label 'java-build'
    }

    options {
        buildDiscarder(logRotator(numToKeepStr: '30'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }

    parameters {
        choice(name: 'BUILD_ENV', choices: ['dev', 'staging', 'prod'], description: 'Target environment')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Execute unit tests')
        booleanParam(name: 'DEPLOY_ARTIFACT', defaultValue: false, description: 'Deploy to repository')
    }

    environment {
        MAVEN_OPTS = '-Xmx1024m -XX:MaxPermSize=512m'
        JAVA_TOOL_OPTIONS = '-Dfile.encoding=UTF-8'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git rev-parse HEAD > commit.txt'
            }
        }

        stage('Build') {
            steps {
                dir('backend') {
                    script {
                        if (fileExists('pom.xml')) {
                            sh 'mvn clean package -DskipTests=false -Dmaven.test.failure.ignore=true'
                        } else if (fileExists('build.gradle')) {
                            sh 'gradle clean build -x test --stacktrace'
                        }
                    }
                }
            }
        }

        stage('Test') {
            when {
                expression { return params.RUN_TESTS }
            }
            steps {
                dir('backend') {
                    script {
                        if (fileExists('pom.xml')) {
                            sh 'mvn test -DskipTests=false'
                            junit '**/target/surefire-reports/*.xml'
                        } else if (fileExists('build.gradle')) {
                            sh 'gradle test'
                            junit '**/build/test-results/test/*.xml'
                        }
                    }
                }
            }
            post {
                always {
                    jacoco()  // If using JaCoCo plugin
                    publishHTML(target: [
                        reportDir: 'backend/target/site/jacoco',
                        reportFiles: 'index.html',
                        reportName: 'Code Coverage Report'
                    ])
                }
            }
        }

        stage('SonarQube Analysis') {
            when {
                expression { return env.SONAR_HOST_URL }
            }
            steps {
                withSonarQubeEnv('sonarqube') {
                    dir('backend') {
                        script {
                            if (fileExists('pom.xml')) {
                                sh 'mvn sonar:sonar -Dsonar.projectKey=${JOB_NAME}'
                            } else if (fileExists('build.gradle')) {
                                sh 'gradle sonarqube -Dsonar.projectKey=${JOB_NAME}'
                            }
                        }
                    }
                }
            }
        }

        stage('Build Artifact') {
            steps {
                dir('backend') {
                    script {
                        if (fileExists('pom.xml')) {
                            sh 'mvn package -DskipTests -Dmaven.repo.local=/tmp/m2'
                            archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                        } else if (fileExists('build.gradle')) {
                            sh 'gradle jar'
                            archiveArtifacts artifacts: 'build/libs/*.jar', fingerprint: true
                        }
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                expression { return params.DEPLOY_ARTIFACT }
            }
            steps {
                script {
                    if (params.BUILD_ENV == 'dev') {
                        echo 'Deploying to Dev environment'
                        // sh 'deploy-to-dev.sh'
                    } else if (params.BUILD_ENV == 'staging') {
                        echo 'Deploying to Staging environment'
                        // sh 'deploy-to-staging.sh'
                    } else if (params.BUILD_ENV == 'prod') {
                        echo 'Deploying to Production environment'
                        // Requires manual approval
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            emailext (
                subject: "SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build completed successfully.\nView: ${env.BUILD_URL}",
                to: 'team@example.com'
            )
        }
        failure {
            emailext (
                subject: "FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: "Build failed.\nView: ${env.BUILD_URL}\nError: ${env.BUILD_URL}console",
                to: 'team@example.com'
            )
        }
    }
}
```

### 4. Configure Jenkins job

1. Create new Pipeline job in Jenkins
2. Set "Pipeline script from SCM"
3. Configure repository URL and credentials
4. Set script path to Jenkinsfile
5. Configure triggers (poll SCM, webhooks, or periodic)

## Verify

1. Run pipeline manually to verify stages execute
2. Verify test results appear in Jenkins
3. Confirm artifacts are archived
4. Check that email notifications work
5. Verify SonarQube results appear (if configured)

## Rollback

If the pipeline fails:

1. Review stage logs in Jenkins UI
2. Check console output for error messages
3. Verify credentials have not expired
4. For deployment rollback: restore previous artifact version in repository

## Common errors

| Error | Solution |
|---|---|
| `mvn: command not found` | Add Maven tool in Global Tool Configuration |
| `Gradle build failed` | Check build.gradle syntax, dependencies |
| `Test failures detected` | Review test output, fix failing tests |
| `SonarQube analysis failed` | Verify SONAR_HOST_URL and token |
| `Artifact upload failed` | Check repository credentials |
| `Permission denied deploying` | Verify deployment credentials |

## References

- Jenkins Pipeline Syntax: https://www.jenkins.io/doc/book/pipeline/syntax/
- Maven Jenkins Plugin: https://github.com/jenkinsci/maven-plugin
- SonarQube Scanner for Jenkins: https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-jenkins/