# Jenkins - CI/CD Server

## Introduction

[Jenkins](https://www.jenkins.io/) is an open-source automation server that provides hundreds of plugins to support building, deploying and automating any project.

## Quick Setup

### Using Docker

```bash
# Basic Jenkins setup
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins jenkins/jenkins:lts

# With persistent volume
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins jenkins/jenkins:lts
```

### Essential CLI Commands

```bash
# Download CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Authentication (use API token)
alias jcli='java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token'

# Common operations
jcli list-jobs
jcli build job-name
jcli console job-name
```

## Groovy Pipeline Scripts

### 1. Go Application CI/CD Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        APP_NAME = 'my-go-app'
        APP_VERSION = "${BUILD_NUMBER}"
        GCP_PROJECT = 'your-gcp-project'
        GCP_REGION = 'us-central1'
        GOOS = 'linux'
        GOARCH = 'amd64'
        CGO_ENABLED = '0'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-org/your-go-repo.git'
            }
        }
        
        stage('Setup Go') {
            steps {
                script {
                    echo "Setting up Go environment for ${APP_NAME} version ${APP_VERSION}"
                    sh 'go version'
                    sh 'go mod download'
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'go test -v ./... -coverprofile=coverage.out'
                        sh 'go tool cover -html=coverage.out -o coverage.html'
                        publishHTML([
                            allowMissing: false,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: '.',
                            reportFiles: 'coverage.html',
                            reportName: 'Go Coverage Report'
                        ])
                    }
                }
                stage('Lint') {
                    steps {
                        sh 'go vet ./...'
                        sh 'gofmt -l .'
                    }
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    sh """
                        echo "Building Go binary for ${APP_NAME}"
                        go build -ldflags="-w -s" -o ${APP_NAME} ./cmd/main.go
                        ls -la ${APP_NAME}
                    """
                }
                archiveArtifacts artifacts: "${APP_NAME}", allowEmptyArchive: false
            }
        }
        
        stage('Build and Push Docker Image') {
            steps {
                script {
                    sh """
                        # Create Dockerfile if it doesn't exist
                        cat > Dockerfile << 'EOF'
FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY ${APP_NAME} .
EXPOSE 8080
CMD ["./${APP_NAME}"]
EOF
                        
                        # Configure Docker for Artifact Registry
                        gcloud auth configure-docker us-central1-docker.pkg.dev
                        
                        # Build and push to Google Cloud Artifact Registry
                        gcloud builds submit --tag us-central1-docker.pkg.dev/\${GCP_PROJECT}/${APP_NAME}/${APP_NAME}:${APP_VERSION} .
                        gcloud builds submit --tag us-central1-docker.pkg.dev/\${GCP_PROJECT}/${APP_NAME}/${APP_NAME}:latest .
                    """
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                script {
                    sh """
                        gcloud run deploy ${APP_NAME}-staging \
                            --image=us-central1-docker.pkg.dev/\${GCP_PROJECT}/${APP_NAME}/${APP_NAME}:${APP_VERSION} \
                            --region=${GCP_REGION} \
                            --platform=managed \
                            --allow-unauthenticated \
                            --set-env-vars=GO_ENV=staging
                    """
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                script {
                    sh """
                        STAGING_URL=\$(gcloud run services describe ${APP_NAME}-staging --region=${GCP_REGION} --format='value(status.url)')
                        curl -f \$STAGING_URL/health || exit 1
                    """
                    echo 'Smoke tests passed!'
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            input {
                message "Deploy to production?"
                ok "Deploy"
                parameters {
                    choice(name: 'DEPLOYMENT_STRATEGY', choices: ['rolling', 'blue-green'], description: 'Deployment strategy')
                }
            }
            steps {
                script {
                    if (params.DEPLOYMENT_STRATEGY == 'blue-green') {
                        sh """
                            # Deploy new revision to Cloud Run with no traffic
                            gcloud run deploy ${APP_NAME} \
                                --image=us-central1-docker.pkg.dev/\${GCP_PROJECT}/${APP_NAME}/${APP_NAME}:${APP_VERSION} \
                                --region=${GCP_REGION} \
                                --platform=managed \
                                --allow-unauthenticated \
                                --set-env-vars=GO_ENV=production \
                                --no-traffic \
                                --tag=blue
                            
                            # Gradually shift traffic to new revision
                            gcloud run services update-traffic ${APP_NAME} \
                                --to-tags=blue=10 \
                                --region=${GCP_REGION}
                        """
                    } else {
                        sh """
                            # Rolling deployment to Cloud Run
                            gcloud run deploy ${APP_NAME} \
                                --image=us-central1-docker.pkg.dev/\${GCP_PROJECT}/${APP_NAME}/${APP_NAME}:${APP_VERSION} \
                                --region=${GCP_REGION} \
                                --platform=managed \
                                --allow-unauthenticated \
                                --set-env-vars=GO_ENV=production
                        """
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
            slackSend(
                channel: '#deployments',
                color: 'good',
                message: "✅ ${APP_NAME} v${APP_VERSION} deployed successfully!"
            )
        }
        failure {
            slackSend(
                channel: '#deployments',
                color: 'danger',
                message: "❌ ${APP_NAME} v${APP_VERSION} deployment failed!"
            )
        }
    }
}
```

### 2. Node.js/React Application Pipeline

```groovy
pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-u root:root'
        }
    }
    
    environment {
        NODE_ENV = 'production'
        AWS_REGION = 'us-west-2'
        S3_BUCKET = 'my-app-frontend'
        CLOUDFRONT_ID = 'E1234567890'
    }
    
    stages {
        stage('Install Dependencies') {
            steps {
                sh 'npm ci --production=false'
            }
        }
        
        stage('Code Quality') {
            parallel {
                stage('Lint') {
                    steps {
                        sh 'npm run lint'
                        publishHTML([
                            allowMissing: false,
                            alwaysLinkToLastBuild: true,
                            keepAll: true,
                            reportDir: 'reports',
                            reportFiles: 'eslint.html',
                            reportName: 'ESLint Report'
                        ])
                    }
                }
                stage('Security Audit') {
                    steps {
                        sh 'npm audit --audit-level moderate'
                    }
                }
                stage('Type Check') {
                    steps {
                        sh 'npm run type-check'
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm run test:ci'
                publishTestResults testResultsPattern: 'coverage/junit.xml'
                publishCoverage adapters: [
                    istanbulCoberturaAdapter('coverage/cobertura-coverage.xml')
                ], sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm run build'
                sh 'ls -la dist/'
            }
        }
        
        stage('Deploy to S3') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                withAWS(credentials: 'aws-credentials', region: env.AWS_REGION) {
                    script {
                        def bucketName = env.BRANCH_NAME == 'main' ? env.S3_BUCKET : "${env.S3_BUCKET}-staging"
                        sh "aws s3 sync dist/ s3://${bucketName}/ --delete --cache-control 'max-age=31536000,public'"
                        sh "aws s3 cp dist/index.html s3://${bucketName}/index.html --cache-control 'max-age=0,no-cache,no-store,must-revalidate'"
                        
                        if (env.BRANCH_NAME == 'main') {
                            sh "aws cloudfront create-invalidation --distribution-id ${env.CLOUDFRONT_ID} --paths '/*'"
                        }
                    }
                }
            }
        }
        
        stage('E2E Tests') {
            when {
                branch 'main'
            }
            agent {
                docker {
                    image 'mcr.microsoft.com/playwright:focal'
                }
            }
            steps {
                sh 'npm install @playwright/test'
                sh 'npx playwright test --reporter=junit'
                publishTestResults testResultsPattern: 'test-results/junit.xml'
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'dist/**/*', fingerprint: true
        }
    }
}
```

### 3. Microservices with Cloud Run

```groovy
pipeline {
    agent any
    
    environment {
        GCP_PROJECT = 'your-gcp-project'
        GCP_REGION = 'us-central1'
    }
    
    stages {
        stage('Build Services') {
            parallel {
                stage('User Service') {
                    steps {
                        dir('user-service') {
                            script {
                                sh """
                                    gcloud builds submit --tag us-central1-docker.pkg.dev/\${GCP_PROJECT}/microservices/user-service:${BUILD_NUMBER} .
                                """
                            }
                        }
                    }
                }
                stage('Order Service') {
                    steps {
                        dir('order-service') {
                            script {
                                sh """
                                    gcloud builds submit --tag us-central1-docker.pkg.dev/\${GCP_PROJECT}/microservices/order-service:${BUILD_NUMBER} .
                                """
                            }
                        }
                    }
                }
                stage('API Gateway') {
                    steps {
                        dir('api-gateway') {
                            script {
                                sh """
                                    gcloud builds submit --tag us-central1-docker.pkg.dev/\${GCP_PROJECT}/microservices/api-gateway:${BUILD_NUMBER} .
                                """
                            }
                        }
                    }
                }
            }
        }
        
        stage('Deploy Services to Cloud Run') {
            steps {
                script {
                    def services = ['user-service', 'order-service', 'api-gateway']
                    
                    services.each { service ->
                        echo "Deploying ${service}..."
                        sh """
                            gcloud run deploy ${service} \
                                --image=us-central1-docker.pkg.dev/\${GCP_PROJECT}/microservices/${service}:${BUILD_NUMBER} \
                                --region=${GCP_REGION} \
                                --platform=managed \
                                --allow-unauthenticated
                        """
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    sh """
                        # Get API Gateway URL
                        API_URL=\$(gcloud run services describe api-gateway --region=${GCP_REGION} --format='value(status.url)')
                        
                        # Run integration tests
                        curl -f \$API_URL/health || exit 1
                        curl -f \$API_URL/users || exit 1
                        curl -f \$API_URL/orders || exit 1
                    """
                }
            }
        }
    }
    
    post {
        always {
            script {
                echo "Microservices deployment completed"
            }
        }
    }
}
}
```

### 4. Security-Focused Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        SONAR_TOKEN = credentials('sonar-token')
        TRIVY_CACHE_DIR = '/tmp/trivy-cache'
    }
    
    stages {
        stage('Source Code Analysis') {
            parallel {
                stage('SonarQube Scan') {
                    steps {
                        withSonarQubeEnv('SonarQube') {
                            sh '''
                                sonar-scanner \
                                    -Dsonar.projectKey=my-project \
                                    -Dsonar.sources=. \
                                    -Dsonar.host.url=http://sonarqube:9000 \
                                    -Dsonar.login=${SONAR_TOKEN}
                            '''
                        }
                    }
                }
                stage('Dependency Check') {
                    steps {
                        sh 'npm audit --audit-level high'
                        sh 'safety check -r requirements.txt || true'
                    }
                }
                stage('Secret Detection') {
                    steps {
                        sh 'truffelhog3 --format json . > secrets-report.json || true'
                        archiveArtifacts artifacts: 'secrets-report.json', allowEmptyArchive: true
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Build Secure Image') {
            steps {
                script {
                    sh '''
                        # Multi-stage build with security best practices
                        docker build \
                            --no-cache \
                            --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                            --build-arg VCS_REF=${GIT_COMMIT} \
                            -t my-app:${BUILD_NUMBER} .
                    '''
                }
            }
        }
        
        stage('Container Security Scan') {
            parallel {
                stage('Trivy Vulnerability Scan') {
                    steps {
                        sh '''
                            trivy image \
                                --cache-dir ${TRIVY_CACHE_DIR} \
                                --format json \
                                --output trivy-report.json \
                                --severity HIGH,CRITICAL \
                                my-app:${BUILD_NUMBER}
                        '''
                        archiveArtifacts artifacts: 'trivy-report.json'
                        
                        // Fail if critical vulnerabilities found
                        script {
                            def trivyReport = readJSON file: 'trivy-report.json'
                            def criticalVulns = trivyReport.Results?.find { it.Vulnerabilities?.any { v -> v.Severity == 'CRITICAL' } }
                            if (criticalVulns) {
                                error "Critical vulnerabilities found in container image"
                            }
                        }
                    }
                }
                stage('Container Configuration Scan') {
                    steps {
                        sh '''
                            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                                aquasec/dockle:latest \
                                --format json \
                                --output dockle-report.json \
                                my-app:${BUILD_NUMBER}
                        '''
                        archiveArtifacts artifacts: 'dockle-report.json'
                    }
                }
            }
        }
        
        stage('Deploy with Security Best Practices') {
            steps {
                script {
                    sh '''
                        # Deploy to Cloud Run with security best practices
                        gcloud run deploy my-app \
                            --image=my-app:${BUILD_NUMBER} \
                            --region=us-central1 \
                            --platform=managed \
                            --no-allow-unauthenticated \
                            --cpu-throttling \
                            --memory=1Gi \
                            --max-instances=10 \
                            --concurrency=100 \
                            --set-env-vars="NODE_ENV=production"
                    '''
                }
            }
        }
        
        stage('Runtime Security Testing') {
            steps {
                script {
                    sh '''
                        # Get Cloud Run service URL for security testing
                        SERVICE_URL=$(gcloud run services describe my-app --region=us-central1 --format='value(status.url)')
                        
                        # OWASP ZAP security testing
                        docker run --rm -v $(pwd):/zap/wrk/:rw \
                            -t owasp/zap2docker-weekly \
                            zap-baseline.py \
                            -t $SERVICE_URL \
                            -J zap-report.json \
                            -r zap-report.html
                    '''
                    
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'zap-report.html',
                        reportName: 'ZAP Security Report'
                    ])
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Cloud Run security configuration report
                sh '''
                    gcloud run services describe my-app --region=us-central1 --format=json > cloud-run-config.json
                '''
                archiveArtifacts artifacts: 'cloud-run-config.json'
            }
        }
        failure {
            emailext (
                subject: "Security Pipeline Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Security vulnerabilities detected in build ${env.BUILD_NUMBER}. Please review the reports.",
                to: "security-team@company.com"
            )
        }
    }
}
```

### 5. Cloud Run Blue-Green Deployment

```groovy
pipeline {
    agent any
    
    environment {
        APP_NAME = 'web-application'
        VERSION = "${BUILD_NUMBER}"
        GCP_PROJECT = 'your-gcp-project'
        GCP_REGION = 'us-central1'
    }
    
    stages {
        stage('Build and Test') {
            steps {
                sh 'go test ./...'
                sh 'go build -o ${APP_NAME} .'
                sh """
                    gcloud builds submit --tag us-central1-docker.pkg.dev/\${GCP_PROJECT}/${APP_NAME}/${APP_NAME}:${VERSION} .
                """
            }
        }
        
        stage('Deploy Blue Version') {
            steps {
                script {
                    // Deploy new version with blue tag, no traffic
                    sh """
                        gcloud run deploy ${APP_NAME} \
                            --image=us-central1-docker.pkg.dev/\${GCP_PROJECT}/${APP_NAME}/${APP_NAME}:${VERSION} \
                            --region=${GCP_REGION} \
                            --platform=managed \
                            --allow-unauthenticated \
                            --no-traffic \
                            --tag=blue-${VERSION}
                    """
                }
            }
        }
        
        stage('Test Blue Version') {
            steps {
                script {
                    // Get blue version URL
                    def blueUrl = sh(
                        script: "gcloud run services describe ${APP_NAME} --region=${GCP_REGION} --format='value(status.traffic[0].url)' | grep blue-${VERSION}",
                        returnStdout: true
                    ).trim()
                    
                    // Test blue version
                    sh "curl -f ${blueUrl}/health || exit 1"
                    echo 'Blue version tests passed!'
                }
            }
        }
        
        stage('Gradual Traffic Switch') {
            input {
                message "Start traffic migration to blue version?"
                ok "Start Migration"
            }
            steps {
                script {
                    // Start with 10% traffic to blue
                    sh """
                        gcloud run services update-traffic ${APP_NAME} \
                            --to-tags=blue-${VERSION}=10 \
                            --region=${GCP_REGION}
                    """
                    
                    echo "10% traffic routed to blue version. Monitoring..."
                    sleep(300) // Monitor for 5 minutes
                    
                    // Increase to 50%
                    sh """
                        gcloud run services update-traffic ${APP_NAME} \
                            --to-tags=blue-${VERSION}=50 \
                            --region=${GCP_REGION}
                    """
                    
                    echo "50% traffic routed to blue version. Monitoring..."
                    sleep(300) // Monitor for 5 minutes
                }
            }
        }
        
        stage('Complete Migration') {
            input {
                message "Complete migration to blue version (100% traffic)?"
                ok "Complete"
            }
            steps {
                script {
                    // Route 100% traffic to blue version
                    sh """
                        gcloud run services update-traffic ${APP_NAME} \
                            --to-tags=blue-${VERSION}=100 \
                            --region=${GCP_REGION}
                    """
                    
                    echo "Blue-green deployment completed successfully!"
                    
                    // Optional: Clean up old revisions after successful deployment
                    sh """
                        gcloud run revisions list --service=${APP_NAME} --region=${GCP_REGION} \
                            --format='value(metadata.name)' | tail -n +6 | \
                            xargs -I {} gcloud run revisions delete {} --region=${GCP_REGION} --quiet || true
                    """
                }
            }
        }
    }
    
    post {
        failure {
            script {
                // Rollback to previous version on failure
                sh """
                    gcloud run services update-traffic ${APP_NAME} \
                        --to-latest \
                        --region=${GCP_REGION}
                """
                echo "Rolled back to previous version due to failure"
            }
        }
    }
}
```

### 6. Database Migration Pipeline

```groovy
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'MIGRATION_TYPE',
            choices: ['forward', 'rollback'],
            description: 'Type of migration to perform'
        )
        string(
            name: 'TARGET_VERSION',
            defaultValue: '',
            description: 'Target migration version (for rollback)'
        )
    }
    
    environment {
        DB_HOST = 'your-cloud-sql-instance'
        DB_PORT = '5432'
        DB_NAME = 'myapp'
        DB_USER = credentials('db-username')
        DB_PASSWORD = credentials('db-password')
        GCP_PROJECT = 'your-gcp-project'
    }
    
    stages {
        stage('Backup Database') {
            steps {
                script {
                    def timestamp = new Date().format('yyyyMMdd-HHmmss')
                    sh """
                        # Run backup using Cloud SQL proxy or direct connection
                        docker run --rm postgres:13 \
                            pg_dump \
                            -h ${DB_HOST} \
                            -p ${DB_PORT} \
                            -U ${DB_USER} \
                            -d ${DB_NAME} \
                            --verbose > backup-${timestamp}.sql
                    """
                    
                    // Store backup in S3 or persistent storage
                    sh """
                        aws s3 cp backup-${timestamp}.sql \
                            s3://database-backups/myapp/backup-${timestamp}.sql
                    """
                    
                    env.BACKUP_FILE = "backup-${timestamp}.sql"
                }
            }
        }
        
        stage('Validate Migrations') {
            steps {
                script {
                    sh """
                        # Validate migrations using Docker
                        docker run --rm migrate/migrate \
                            -source file:///migrations \
                            -database "postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable" \
                            version
                    """
                }
            }
        }
        
        stage('Run Migration') {
            steps {
                script {
                    if (params.MIGRATION_TYPE == 'forward') {
                        sh """
                            docker run --rm -v \$(pwd)/migrations:/migrations migrate/migrate \
                                -source file:///migrations \
                                -database "postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable" \
                                up
                        """
                    } else if (params.MIGRATION_TYPE == 'rollback' && params.TARGET_VERSION) {
                        sh """
                            docker run --rm -v \$(pwd)/migrations:/migrations migrate/migrate \
                                -source file:///migrations \
                                -database "postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable" \
                                goto ${params.TARGET_VERSION}
                        """
                    }
                }
            }
        }
        
        stage('Verify Migration') {
            steps {
                script {
                    sh """
                        # Verify migration using Docker
                        docker run --rm postgres:13 \
                            psql \
                            -h ${DB_HOST} \
                            -p ${DB_PORT} \
                            -U ${DB_USER} \
                            -d ${DB_NAME} \
                            -c "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 5;"
                    """
                    
                    // Run data integrity checks
                    sh """
                        docker run --rm -v \$(pwd)/integrity-checks.sql:/integrity-checks.sql postgres:13 \
                            psql \
                            -h ${DB_HOST} \
                            -p ${DB_PORT} \
                            -U ${DB_USER} \
                            -d ${DB_NAME} \
                            -f /integrity-checks.sql
                    """
                }
            }
        }
        
        stage('Update Application') {
            when {
                expression { params.MIGRATION_TYPE == 'forward' }
            }
            steps {
                script {
                    // Deploy new application version that uses migrated schema
                    sh """
                        gcloud run deploy myapp \
                            --image=us-central1-docker.pkg.dev/\${GCP_PROJECT}/myapp/myapp:${BUILD_NUMBER} \
                            --region=us-central1 \
                            --platform=managed \
                            --allow-unauthenticated
                    """
                }
            }
        }
        
        stage('Post-Migration Tests') {
            steps {
                script {
                    sh """
                        # Run post-migration tests using Docker
                        docker run --rm myapp-tests:latest \
                            npm run test:integration
                    """
                }
            }
        }
    }
    
    post {
        failure {
            script {
                if (params.MIGRATION_TYPE == 'forward') {
                    echo "Migration failed. Consider manual rollback using backup: ${env.BACKUP_FILE}"
                    
                    // Optionally perform automatic rollback
                    input message: "Migration failed. Perform automatic rollback?", ok: "Rollback"
                    
                    sh """
                        # Emergency rollback using Docker
                        docker run --rm postgres:13 sh -c "
                            aws s3 cp s3://database-backups/myapp/${env.BACKUP_FILE} - | \
                            psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME}
                        "
                    """
                }
            }
        }
        always {
            script {
                // Clean up backup files older than 30 days
                sh """
                    aws s3 ls s3://database-backups/myapp/ | \
                    awk '\$1 <= "'$(date -d '30 days ago' '+%Y-%m-%d')'" {print \$4}' | \
                    xargs -I {} aws s3 rm s3://database-backups/myapp/{}
                """
            }
        }
    }
}
```

## Advanced Jenkins Configuration

### Global Pipeline Libraries

Create shared libraries for common CI/CD patterns:

```groovy
// vars/deployToCloudRun.groovy
def call(Map config) {
    script {
        sh """
            gcloud run deploy ${config.name} \
                --image=${config.image}:${config.tag} \
                --region=${config.region ?: 'us-central1'} \
                --platform=managed \
                --allow-unauthenticated
        """
        
        // Health check
        sh """
            SERVICE_URL=\$(gcloud run services describe ${config.name} --region=${config.region ?: 'us-central1'} --format='value(status.url)')
            curl -f \$SERVICE_URL/health || exit 1
        """
    }
}

// Usage in Jenkinsfile:
// deployToCloudRun([
//     name: 'my-app',
//     image: 'us-central1-docker.pkg.dev/my-project/my-app/my-app',
//     tag: BUILD_NUMBER,
//     region: 'us-central1'
// ])
```

### Jenkins Configuration as Code (JCasC)

```yaml
jenkins:
  systemMessage: "Jenkins managed by Configuration as Code"
  numExecutors: 2
  scmCheckoutRetryCount: 3
  mode: NORMAL
  
  globalNodeProperties:
    - envVars:
        env:
          - key: "DOCKER_REGISTRY"
            value: "your-registry.com"
          - key: "KUBE_NAMESPACE"
            value: "default"

  clouds:
    - kubernetes:
        name: "kubernetes"
        serverUrl: "https://kubernetes.default.svc.cluster.local"
        namespace: "jenkins"
        jenkinsUrl: "http://jenkins:8080"
        jenkinsTunnel: "jenkins-agent:50000"
        templates:
          - name: "default"
            label: "jenkins-slave"
            containers:
              - name: "jnlp"
                image: "jenkins/inbound-agent:latest"
                resourceRequestCpu: "500m"
                resourceRequestMemory: "1Gi"
                resourceLimitCpu: "1000m"
                resourceLimitMemory: "2Gi"

credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              scope: GLOBAL
              id: "docker-registry"
              username: "registry-user"
              password: "registry-password"
          - kubernetesServiceAccount:
              scope: GLOBAL
              id: "kubernetes-service-account"
          - aws:
              scope: GLOBAL
              id: "aws-credentials"
              accessKey: "AKIA..."
              secretKey: "secret..."

security:
  scriptApproval:
    approvedSignatures:
      - "method groovy.json.JsonSlurperClassic parseText java.lang.String"
      - "new groovy.json.JsonSlurperClassic"

unclassified:
  sonarGlobalConfiguration:
    installations:
      - name: "SonarQube"
        serverUrl: "http://sonarqube:9000"
        credentialsId: "sonar-token"
  
  slackNotifier:
    teamDomain: "your-team"
    token: "xoxb-your-token"
    room: "#jenkins"
```

## Troubleshooting

### Common Pipeline Issues

```bash
# Check Jenkins logs
docker logs jenkins

# Debug pipeline syntax
curl -X POST -F "jenkinsfile=<Jenkinsfile" http://localhost:8080/pipeline-model-converter/validate

# Test Groovy scripts
http://localhost:8080/script
```

### Pipeline Best Practices

1. **Use Declarative Pipeline** syntax when possible
2. **Implement proper error handling** with try-catch blocks
3. **Use shared libraries** for common functionality
4. **Cache dependencies** to speed up builds
5. **Implement proper secrets management**
6. **Use parallel execution** for independent tasks
7. **Implement comprehensive testing** at each stage
8. **Monitor pipeline performance** and optimize bottlenecks
