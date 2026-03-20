# Jenkins Pipeline Groovy Snippets for Scripted Pipelines

A comprehensive collection of Groovy code snippets for Jenkins scripted pipelines. These snippets are designed for use in Jenkinsfile scripted syntax.

## Table of Contents

1. [Basic Structure](#basic-structure)
2. [Node and Stage Blocks](#node-and-stage-blocks)
3. [Variable Handling](#variable-handling)
4. [Conditional Execution](#conditional-execution)
5. [Loops and Iteration](#loops-and-iteration)
6. [Error Handling](#error-handling)
7. [Parallel Execution](#parallel-execution)
8. [Docker Integration](#docker-integration)
9. [Git Operations](#git-operations)
10. [File Operations](#file-operations)
11. [HTTP and API Calls](#http-and-api-calls)
12. [Credential Handling](#credential-handling)
13. [Email Notifications](#email-notifications)
14. [Artifact Management](#artifact-management)
15. [Testing Integration](#testing-integration)

---

## Basic Structure

### Minimal Scripted Pipeline
```groovy
node {
    stage('Build') {
        echo 'Building...'
    }
    stage('Test') {
        echo 'Testing...'
    }
    stage('Deploy') {
        echo 'Deploying...'
    }
}
```

### Scripted Pipeline with Environment
```groovy
node {
    environment {
        APP_NAME = 'myapp'
        BUILD_VERSION = "${env.BUILD_NUMBER}"
    }
    
    stage('Initialize') {
        echo "Building ${APP_NAME} version ${BUILD_VERSION}"
    }
}
```

---

## Node and Stage Blocks

### Single Node, Multiple Stages
```groovy
node('docker') {
    stage('Checkout') {
        checkout scm
    }
    
    stage('Build') {
        sh 'make build'
    }
    
    stage('Test') {
        sh 'make test'
    }
    
    stage('Deploy') {
        sh 'make deploy'
    }
}
```

### Multiple Nodes (Distributed Builds)
```groovy
node('linux') {
    stage('Build on Linux') {
        sh 'echo Building on Linux'
    }
}

node('windows') {
    stage('Build on Windows') {
        bat 'echo Building on Windows'
    }
}
```

### Stage with Timeout and Retry
```groovy
stage('Deploy') {
    timeout(time: 30, unit: 'MINUTES') {
        retry(3) {
            sh './deploy.sh'
        }
    }
}
```

---

## Variable Handling

### Defining Variables
```groovy
node {
    // String variable
    def appName = 'myapp'
    
    // Multi-line string
    def deploymentScript = """
        kubectl apply -f deployment.yaml
        kubectl rollout status deployment/${appName}
    """
    
    // Map/Object
    def config = [
        region: 'us-east-1',
        instanceType: 't3.medium',
        desiredCapacity: 3
    ]
    
    // List/Array
    def services = ['web', 'api', 'worker']
    
    stage('Print Variables') {
        echo "App: ${appName}"
        echo "Region: ${config.region}"
        echo "First service: ${services[0]}"
    }
}
```

### Environment Variables
```groovy
node {
    environment {
        // Static value
        ENV_NAME = 'production'
        
        // Dynamic value from shell
        GIT_COMMIT_SHORT = "${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
        
        // From Jenkins built-in variables
        BUILD_URL_FULL = "${env.BUILD_URL}"
    }
    
    stage('Show Env') {
        sh 'printenv | grep -E "^(ENV_NAME|BUILD_)" | head -5'
    }
}
```

---

## Conditional Execution

### If-Else Block
```groovy
node {
    stage('Conditional Build') {
        def isMaster = env.BRANCH_NAME == 'master'
        def shouldDeploy = env.BRANCH_NAME == 'master' || env.BRANCH_NAME == 'release'
        
        if (shouldDeploy) {
            echo 'Deploying...'
            sh 'make deploy'
        } else {
            echo 'Skipping deployment for non-production branch'
        }
    }
}
```

### Switch Statement
```groovy
node {
    stage('Branch Strategy') {
        switch (env.BRANCH_NAME) {
            case 'master':
                echo 'Deploying to production'
                break
            case 'develop':
                echo 'Deploying to staging'
                break
            case ~/feature\/.*/:
                echo 'Deploying to feature environment'
                break
            default:
                echo 'Running pull request tests'
        }
    }
}
```

### Boolean Condition
```groovy
node {
    stage('Conditional Test') {
        def runIntegrationTests = params.RUN_INTEGRATION_TESTS ?: false
        
        stage('Unit Tests') {
            sh 'make unit-test'
        }
        
        if (runIntegrationTests) {
            stage('Integration Tests') {
                sh 'make integration-test'
            }
        }
    }
}
```

---

## Loops and Iteration

### List Iteration
```groovy
node {
    stage('Deploy Multiple Services') {
        def services = ['auth', 'api', 'web', 'worker']
        
        services.each { service ->
            echo "Deploying ${service}..."
            sh "./deploy.sh ${service}"
        }
    }
}
```

### Map Iteration
```groovy
node {
    stage('Deploy to Regions') {
        def regions = [
            'us-east-1': '10.0.1.0/24',
            'us-west-2': '10.0.2.0/24',
            'eu-west-1': '10.0.3.0/24'
        ]
        
        regions.each { region, cidr ->
            echo "Deploying to ${region} with CIDR ${cidr}"
            sh "./deploy.sh --region ${region} --cidr ${cidr}"
        }
    }
}
```

### Range Iteration
```groovy
node {
    stage('Retry Build') {
        // Retry up to 5 times
        for (int i = 1; i <= 5; i++) {
            try {
                sh './build.sh'
                break
            } catch (Exception e) {
                echo "Attempt ${i} failed: ${e.message}"
                if (i == 5) throw e
            }
        }
    }
}
```

---

## Error Handling

### Try-Catch-Finally
```groovy
node {
    stage('Build with Error Handling') {
        try {
            sh './build.sh'
            echo 'Build succeeded'
        } catch (Exception e) {
            echo "Build failed: ${e.message}"
            currentBuild.result = 'FAILURE'
            throw e
        } finally {
            echo 'Cleaning up...'
            sh 'make clean'
        }
    }
}
```

### Catch Error and Continue
```groovy
node {
    stage('Multiple Tasks') {
        catchError(buildResult: 'SUCCESS', message: 'Test failed') {
            sh './run-tests.sh'
        }
        echo 'Continuing despite test failures'
    }
}
```

### Custom Error Handling
```groovy
node {
    stage('Validate Input') {
        if (!params.VERSION) {
            error('VERSION parameter is required')
        }
        
        def validVersions = ['1.0.0', '2.0.0', '3.0.0']
        if (!validVersions.contains(params.VERSION)) {
            error("Invalid version: ${params.VERSION}")
        }
    }
}
```

---

## Parallel Execution

### Parallel Stages
```groovy
node {
    stage('Build in Parallel') {
        def branches = [
            'frontend': { sh './build-frontend.sh' },
            'backend': { sh './build-backend.sh' },
            'worker': { sh './build-worker.sh' }
        ]
        
        parallel branches
    }
}
```

### Parallel with Fail Fast
```groovy
node {
    stage('Test Suites') {
        def testResults = [:]
        
        testResults['unit'] = {
            sh './test-unit.sh'
        }
        testResults['integration'] = {
            sh './test-integration.sh'
        }
        testResults['e2e'] = {
            sh './test-e2e.sh'
        }
        
        parallel(testResults)
    }
}
```

### Staged Parallel Execution
```groovy
node {
    stage('Setup') {
        sh './setup.sh'
    }
    
    stage('Parallel Build') {
        parallel(
            'Frontend': {
                node('frontend') {
                    sh './build-fe.sh'
                }
            },
            'Backend': {
                node('backend') {
                    sh './build-be.sh'
                }
            }
        )
    }
}
```

---

## Docker Integration

### Build Docker Image
```groovy
node {
    stage('Build Docker Image') {
        def imageName = "myapp:${env.BUILD_NUMBER}"
        
        sh """
            docker build -t ${imageName} .
            docker tag ${imageName} myapp:latest
        """
    }
}
```

### Build and Push with Registry
```groovy
node {
    stage('Build and Push') {
        withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            sh '''
                docker login -u $USER -p $PASS
                docker build -t myapp:${BUILD_NUMBER} .
                docker push myapp:${BUILD_NUMBER}
                docker logout
            '''
        }
    }
}
```

### Multi-Stage Docker Build
```groovy
node {
    stage('Multi-Stage Build') {
        sh '''
            docker build \
                --target builder \
                -t myapp:builder .
            
            docker build \
                --target production \
                -t myapp:prod .
        '''
    }
}
```

### Docker with Container
```groovy
node {
    stage('Test in Container') {
        def testImage = 'ubuntu:22.04'
        
        docker.image(testImage).inside {
            sh '''
                apt-get update
                apt-get install -y curl
                ./run-tests.sh
            '''
        }
    }
}
```

---

## Git Operations

### Clone and Build
```groovy
node {
    stage('Checkout') {
        def gitUrl = 'https://github.com/org/repo.git'
        def branch = env.BRANCH_NAME ?: 'master'
        
        git branch: branch, url: gitUrl
    }
    
    stage('Build') {
        sh 'make build'
    }
}
```

### Git Tagging
```groovy
node {
    stage('Tag Release') {
        def version = params.VERSION ?: env.BUILD_NUMBER
        
        sh """
            git config user.email "jenkins@example.com"
            git config user.name "Jenkins"
            git tag -a v${version} -m "Release v${version}"
            git push origin v${version}
        """
    }
}
```

### Git Changelog
```groovy
node {
    stage('Generate Changelog') {
        def changeLog = getChangeLog()
        
        if (changeLog) {
            echo "Changes since last build:"
            changeLog.each { change ->
                echo "* ${change.msg} - ${change.author}"
            }
        }
    }
}
```

---

## File Operations

### Read and Write Files
```groovy
node {
    stage('File Operations') {
        // Write to file
        writeFile file: 'config.json', text: '{"key": "value"}'
        
        // Read file content
        def content = readFile 'config.json'
        echo "Config: ${content}"
        
        // Read file as JSON
        def config = readJSON text: content
        echo "App: ${config.app}"
    }
}
```

### File Glob and Archive
```groovy
node {
    stage('Archive Artifacts') {
        // Find files matching pattern
        def artifacts = findFiles(glob: '**/target/*.jar')
        
        artifacts.each { artifact ->
            echo "Found: ${artifact.name}"
        }
        
        // Archive
        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
    }
}
```

### Temp File Operations
```groovy
node {
    stage('Temp Files') {
        def tempFile = "${env.WORKSPACE}/temp-${env.BUILD_NUMBER}.txt"
        
        writeFile file: tempFile, text: 'Temporary data'
        
        sh "cat ${tempFile}"
        
        // Clean up
        sh "rm -f ${tempFile}"
    }
}
```

---

## HTTP and API Calls

### REST API GET
```groovy
node {
    stage('API Call') {
        def response = httpRequest(
            url: 'https://api.example.com/status',
            acceptHeaders: ['application/json'],
            httpMode: 'GET'
        )
        
        echo "Status: ${response.status}"
        echo "Body: ${response.content}"
    }
}
```

### REST API POST with JSON
```groovy
node {
    stage('Post Deployment') {
        def payload = [
            service: 'myapp',
            version: env.BUILD_NUMBER,
            status: 'deployed'
        ]
        
        httpRequest(
            url: 'https://api.example.com/deployments',
            httpMode: 'POST',
            contentType: 'APPLICATION_JSON',
            requestBody: groovy.json.JsonOutput.toJson(payload),
            validResponseCodes: '200,201,202'
        )
    }
}
```

### REST API with Authentication
```groovy
node {
    stage('Authenticated API Call') {
        withCredentials([usernamePassword(credentialsId: 'api-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            def response = httpRequest(
                url: 'https://api.example.com/data',
                authentication: 'api-creds',
                httpMode: 'GET'
            )
            
            echo "Response: ${response.status}"
        }
    }
}
```

---

## Credential Handling

### Username/Password
```groovy
node {
    stage('Deploy with Credentials') {
        withCredentials([usernamePassword(credentialsId: 'deploy-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
            sh '''
                echo "Deploying as user: $USER"
                ./deploy.sh --user $USER --password $PASS
            '''
        }
    }
}
```

### SSH Key
```groovy
node {
    stage('Git with SSH') {
        withCredentials([sshUserPrivateKey(credentialsId: 'github-ssh', keyFileVariable: 'SSH_KEY', passphraseVariable: 'PASSPHRASE')]) {
            sh '''
                export GIT_SSH_COMMAND="ssh -i $SSH_KEY"
                git clone git@github.com:org/repo.git
            '''
        }
    }
}
```

### Secret Text
```groovy
node {
    stage('Use Secret') {
        withCredentials([string(credentialsId: 'api-key', variable: 'API_KEY')]) {
            sh '''
                curl -H "Authorization: Bearer $API_KEY" https://api.example.com
            '''
        }
    }
}
```

---

## Email Notifications

### Basic Email
```groovy
node {
    stage('Send Email') {
        emailext(
            subject: "Build ${env.JOB_NAME} #${env.BUILD_NUMBER} - ${currentBuild.result ?: 'SUCCESS'}",
            body: """
                Build URL: ${env.BUILD_URL}
                Build Number: ${env.BUILD_NUMBER}
                Status: ${currentBuild.result ?: 'SUCCESS'}
            """,
            to: 'team@example.com',
            from: 'jenkins@example.com'
        )
    }
}
```

### Email with Attachments
```groovy
node {
    stage('Email Test Results') {
        emailext(
            subject: "Test Results: ${env.JOB_NAME}",
            body: "See attached test reports",
            to: 'team@example.com',
            attachmentsPattern: '**/test-results/*.xml'
        )
    }
}
```

---

## Artifact Management

### Archive Build Outputs
```groovy
node {
    stage('Archive') {
        archiveArtifacts(
            artifacts: 'build/**/*.jar,dist/**/*.zip',
            fingerprint: true,
            allowEmptyArchive: false,
            defaultExcludes: false
        )
    }
}
```

### Stash and Unstash
```groovy
node {
    stage('Build') {
        sh 'make build'
        stash name: 'build-output', includes: 'build/**'
    }
    
    node('other') {
        stage('Deploy') {
            unstash 'build-output'
            sh './deploy.sh'
        }
    }
}
```

---

## Testing Integration

### JUnit Test Results
```groovy
node {
    stage('Test') {
        sh './gradlew test'
        
        junit 'build/test-results/**/*.xml'
    }
}
```

### Code Coverage
```groovy
node {
    stage('Coverage') {
        sh './gradlew test jacocoTestReport'
        
        publishHTML([
            allowMissing: false,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: 'build/reports/jacoco',
            reportFiles: 'index.html',
            reportName: 'Coverage Report'
        ])
    }
}
```

### Integration with SonarQube
```groovy
node {
    stage('SonarQube Analysis') {
        withSonarQubeEnv('sonar-server') {
            sh './gradlew sonarqube'
        }
    }
}
```

---

## Additional Resources

- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Jenkins Scripted Pipeline Examples](https://github.com/jenkinsci/pipeline-examples)
- [Jenkins Pipeline Steps Reference](https://www.jenkins.io/doc/pipeline/steps/)

---

*Last updated: 2026-03-20*
