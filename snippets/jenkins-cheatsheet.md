# Jenkins Cheatsheet

## Declarative Pipeline - Docker Build and Push

### Basic Docker Build and Push
```groovy
pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'docker.io'
        IMAGE_NAME = 'myapp'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def image = docker.build("${IMAGE_NAME}:${DOCKER_TAG}")
                }
            }
        }

        stage('Push to Registry') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-hub-credentials') {
                        def image = docker.image("${IMAGE_NAME}:${DOCKER_TAG}")
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo "Pipeline failed!"
        }
    }
}
```

### Multi-Stage Docker Build with BuildKit
```groovy
pipeline {
    agent {
        docker {
            image 'docker:24-dind'
            args '--privileged'
        }
    }

    environment {
        DOCKER_BUILDKIT = '1'
        COMPOSE_DOCKER_CLI_BUILD = '1'
    }

    stages {
        stage('Build') {
            steps {
                sh '''
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    docker run --rm ${IMAGE_NAME}:${BUILD_NUMBER} test
                '''
            }
        }

        stage('Push') {
            when {
                branch 'main'
            }
            steps {
                sh '''
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${REGISTRY}/${IMAGE_NAME}:latest
                    docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
                    docker push ${REGISTRY}/${IMAGE_NAME}:latest
                '''
            }
        }
    }
}
```

### Docker Build with Args and Labels
```groovy
pipeline {
    agent any

    parameters {
        string(name: 'DOCKERFILE_PATH', defaultValue: 'Dockerfile', description: 'Path to Dockerfile')
        string(name: 'BUILD_ARGS', defaultValue: '', description: 'Build arguments')
        booleanParam(name: 'PUSH_IMAGE', defaultValue: true, description: 'Push image after build')
    }

    stages {
        stage('Build with Args') {
            steps {
                script {
                    def buildArgs = params.BUILD_ARGS.split(',').collect { "--build-arg ${it.trim()}" }.join(' ')
                    sh """
                        docker build \
                            ${buildArgs} \
                            -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                            -f ${params.DOCKERFILE_PATH} \
                            .
                    """
                }
            }
        }

        stage('Push Image') {
            when {
                expression { return params.PUSH_IMAGE }
            }
            steps {
                script {
                    docker.withRegistry('https://registry.example.com', 'docker-creds') {
                        docker.image("${IMAGE_NAME}:${BUILD_NUMBER}").push()
                    }
                }
            }
        }
    }
}
```

### Multi-Architecture Build
```groovy
pipeline {
    environment {
        PLATFORMS = 'linux/amd64,linux/arm64'
    }

    stages {
        stage('Set Tag') {
            steps {
                script {
                    env.TAG = env.TAG ?: "${env.BUILD_NUMBER}"
                }
            }
        }

        stage('Build Multi-Platform') {
            steps {
                script {
                    sh '''
                        docker buildx create --name mybuilder --use
                        docker buildx inspect mybuilder --bootstrap
                        docker buildx build \
                            --platform ${PLATFORMS} \
                            -t ${IMAGE_NAME}:${TAG} \
                            --push \
                            .
                    '''
                }
            }
        }
    }
}
```

### Using Dockerfile from Subdirectory
```groovy
pipeline {
    stages {
        stage('Build from Subdirectory') {
            steps {
                dir('backend') {
                    script {
                        def image = docker.build("backend:${env.BUILD_NUMBER}")
                    }
                }
            }
        }
    }
}
```

## Common Snippets

### Docker Credentials (Jenkins Credentials)
```groovy
docker.withRegistry('https://index.docker.io/v1/', 'docker-hub-id') {
    // push, pull, etc.
}
```

### Using Kaniko (No Docker Daemon)
```groovy
stage('Build with Kaniko') {
    agent {
        kubernetes {
            yaml '''
                apiVersion: v1
                kind: Pod
                spec:
                  containers:
                  - name: kaniko
                    image: gcr.io/kaniko-project/executor:v1.15.0
                    args:
                    - --destination=${REGISTRY}/${IMAGE}:${TAG}
                    volumeMounts:
                    - name: kaniko-secret
                      mountPath: /secret
            '''
        }
    }
    steps {
        sh '''
            cp /secret/kaniko-secret/.dockerconfigjson /kaniko/.dockerconfigjson
            /kaniko/executor
        '''
    }
}
```

### Build and Cache
```groovy
stage('Build with Cache') {
    steps {
        script {
            def image = docker.build("myapp:${BUILD_NUMBER}", """
                --cache-from myapp:previous \
                --build-arg BUILD_DATE=${new Date().format("yyyy-MM-dd'T'HH:mm:ss'Z'")} \
                --build-arg VCS_REF=${env.GIT_COMMIT} \
                --build-arg VERSION=${env.BUILD_NUMBER} \
                .
            """)
        }
    }
}
```

### Cleanup Docker
```groovy
post {
    always {
        sh 'docker system prune -f || true'
    }
}
```

## Best Practices

### Security
- Store credentials in Jenkins Credentials store
- Use Docker Content Trust (DCT) for production
- Scan images for vulnerabilities before push
- Use minimal base images
- Don't run as root in containers

### Performance
- Use Docker layer caching
- Use BuildKit for parallel builds
- Multi-stage builds to reduce image size
- Tag images with unique identifiers (build number, git SHA)

### Maintenance
- Use environment variables for registry/image names
- Clean up old images in post build
- Use input steps for manual approval gates
- Add timeout to prevent hung builds
