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

### 1. Basic CI/CD Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        APP_NAME = 'my-application'
        APP_VERSION = "${BUILD_NUMBER}"
        GCP_PROJECT = 'your-gcp-project'
        GCP_REGION = 'us-central1'
    }
    
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/your-org/your-repo.git'
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo "Building ${APP_NAME} version ${APP_VERSION}"
                    sh 'mvn clean compile'
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh 'mvn test'
                        publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh 'mvn integration-test'
                    }
                }
            }
        }
        
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
                archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: false
            }
        }
        
        stage('Build and Push to Artifact Registry') {
            steps {
                script {
                    sh """
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
                            --set-env-vars=NODE_ENV=staging
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
                                --set-env-vars=NODE_ENV=production \
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
                                --set-env-vars=NODE_ENV=production
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

### 3. Multi-Environment Deployment Pipeline

```groovy
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Target environment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip test execution'
        )
        string(
            name: 'VERSION_TAG',
            defaultValue: '',
            description: 'Specific version to deploy (optional)'
        )
    }
    
    environment {
        APP_NAME = 'microservice-api'
        VERSION = params.VERSION_TAG ?: "${BUILD_NUMBER}"
        KUBECONFIG_CRED = credentials('kubernetes-config')
    }
    
    stages {
        stage('Setup Environment') {
            steps {
                script {
                    env.NAMESPACE = params.ENVIRONMENT
                    env.REPLICAS = params.ENVIRONMENT == 'production' ? '3' : '1'
                    env.RESOURCE_LIMITS = params.ENVIRONMENT == 'production' ? 'high' : 'low'
                    
                    switch(params.ENVIRONMENT) {
                        case 'dev':
                            env.DB_HOST = 'dev-postgres.internal'
                            env.REDIS_HOST = 'dev-redis.internal'
                            break
                        case 'staging':
                            env.DB_HOST = 'staging-postgres.internal'
                            env.REDIS_HOST = 'staging-redis.internal'
                            break
                        case 'production':
                            env.DB_HOST = 'prod-postgres.internal'
                            env.REDIS_HOST = 'prod-redis.internal'
                            break
                    }
                }
            }
        }
        
        stage('Build and Test') {
            when {
                not { params.SKIP_TESTS }
            }
            steps {
                sh 'docker build -t ${APP_NAME}:${VERSION} .'
                sh 'docker run --rm ${APP_NAME}:${VERSION} npm test'
            }
        }
        
        stage('Database Migration') {
            when {
                anyOf {
                    params.ENVIRONMENT == 'staging'
                    params.ENVIRONMENT == 'production'
                }
            }
            steps {
                script {
                    sh """
                        kubectl create job migration-${BUILD_NUMBER} \
                            --from=cronjob/db-migration \
                            -n ${NAMESPACE}
                        kubectl wait --for=condition=complete \
                            --timeout=300s \
                            job/migration-${BUILD_NUMBER} \
                            -n ${NAMESPACE}
                    """
                }
            }
        }
        
        stage('Deploy Application') {
            steps {
                script {
                    writeFile file: 'deployment.yaml', text: """
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  namespace: ${NAMESPACE}
spec:
  replicas: ${REPLICAS}
  selector:
    matchLabels:
      app: ${APP_NAME}
  template:
    metadata:
      labels:
        app: ${APP_NAME}
        version: "${VERSION}"
    spec:
      containers:
      - name: ${APP_NAME}
        image: ${APP_NAME}:${VERSION}
        env:
        - name: NODE_ENV
          value: "${ENVIRONMENT}"
        - name: DB_HOST
          value: "${DB_HOST}"
        - name: REDIS_HOST
          value: "${REDIS_HOST}"
        resources:
          requests:
            memory: "${RESOURCE_LIMITS == 'high' ? '512Mi' : '256Mi'}"
            cpu: "${RESOURCE_LIMITS == 'high' ? '500m' : '250m'}"
          limits:
            memory: "${RESOURCE_LIMITS == 'high' ? '1Gi' : '512Mi'}"
            cpu: "${RESOURCE_LIMITS == 'high' ? '1000m' : '500m'}"
"""
                    
                    sh """
                        kubectl apply -f deployment.yaml
                        kubectl rollout status deployment/${APP_NAME} -n ${NAMESPACE} --timeout=300s
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    def maxRetries = 10
                    def retryCount = 0
                    def healthUrl = "http://${APP_NAME}-service.${NAMESPACE}.svc.cluster.local:8080/health"
                    
                    while (retryCount < maxRetries) {
                        try {
                            sh "kubectl run health-check-${BUILD_NUMBER} --rm -i --restart=Never --image=curlimages/curl -- curl -f ${healthUrl}"
                            echo "Health check passed!"
                            break
                        } catch (Exception e) {
                            retryCount++
                            if (retryCount >= maxRetries) {
                                error "Health check failed after ${maxRetries} attempts"
                            }
                            sleep(30)
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            script {
                def message = "🚀 Successfully deployed ${APP_NAME} v${VERSION} to ${params.ENVIRONMENT}"
                slackSend(channel: "#deployments", color: 'good', message: message)
            }
        }
        failure {
            script {
                def message = "💥 Failed to deploy ${APP_NAME} v${VERSION} to ${params.ENVIRONMENT}"
                slackSend(channel: "#deployments", color: 'danger', message: message)
            }
        }
    }
}
```

### 4. Microservices Orchestration Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-registry.com'
        NAMESPACE = 'microservices'
    }
    
    stages {
        stage('Build Services') {
            parallel {
                stage('User Service') {
                    steps {
                        dir('user-service') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/user-service:${BUILD_NUMBER}")
                                docker.withRegistry('https://' + DOCKER_REGISTRY, 'registry-creds') {
                                    image.push()
                                }
                            }
                        }
                    }
                }
                stage('Order Service') {
                    steps {
                        dir('order-service') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/order-service:${BUILD_NUMBER}")
                                docker.withRegistry('https://' + DOCKER_REGISTRY, 'registry-creds') {
                                    image.push()
                                }
                            }
                        }
                    }
                }
                stage('Payment Service') {
                    steps {
                        dir('payment-service') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/payment-service:${BUILD_NUMBER}")
                                docker.withRegistry('https://' + DOCKER_REGISTRY, 'registry-creds') {
                                    image.push()
                                }
                            }
                        }
                    }
                }
                stage('API Gateway') {
                    steps {
                        dir('api-gateway') {
                            script {
                                def image = docker.build("${DOCKER_REGISTRY}/api-gateway:${BUILD_NUMBER}")
                                docker.withRegistry('https://' + DOCKER_REGISTRY, 'registry-creds') {
                                    image.push()
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Deploy Infrastructure') {
            steps {
                script {
                    sh """
                        helm upgrade --install microservices-infra ./helm/infrastructure \
                            --namespace ${NAMESPACE} \
                            --create-namespace \
                            --wait
                    """
                }
            }
        }
        
        stage('Deploy Services in Order') {
            steps {
                script {
                    def services = ['user-service', 'order-service', 'payment-service', 'api-gateway']
                    
                    services.each { service ->
                        echo "Deploying ${service}..."
                        sh """
                            helm upgrade --install ${service} ./helm/${service} \
                                --namespace ${NAMESPACE} \
                                --set image.tag=${BUILD_NUMBER} \
                                --set image.registry=${DOCKER_REGISTRY} \
                                --wait --timeout=300s
                        """
                        
                        // Wait for service to be ready
                        sh """
                            kubectl wait --for=condition=ready pod \
                                -l app=${service} \
                                -n ${NAMESPACE} \
                                --timeout=300s
                        """
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    sh """
                        kubectl run integration-tests-${BUILD_NUMBER} \
                            --rm -i --restart=Never \
                            --image=${DOCKER_REGISTRY}/integration-tests:latest \
                            --env="API_GATEWAY_URL=http://api-gateway.${NAMESPACE}.svc.cluster.local:8080" \
                            -n ${NAMESPACE}
                    """
                }
            }
        }
        
        stage('Performance Tests') {
            steps {
                script {
                    sh """
                        kubectl run load-test-${BUILD_NUMBER} \
                            --rm -i --restart=Never \
                            --image=loadimpact/k6:latest \
                            --command -- k6 run \
                            --vus 50 \
                            --duration 5m \
                            /scripts/load-test.js
                    """
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Collect logs from all services
                def services = ['user-service', 'order-service', 'payment-service', 'api-gateway']
                services.each { service ->
                    sh """
                        kubectl logs -l app=${service} -n ${NAMESPACE} \
                            --tail=100 > ${service}-logs.txt || true
                    """
                }
                archiveArtifacts artifacts: '*-logs.txt', allowEmptyArchive: true
            }
        }
    }
}
```

### 5. Security-Focused Pipeline

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
        
        stage('Deploy with Security Policies') {
            steps {
                script {
                    writeFile file: 'security-policy.yaml', text: '''
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: my-app-network-policy
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          role: database
    ports:
    - protocol: TCP
      port: 5432
---
apiVersion: v1
kind: SecurityContext
metadata:
  name: my-app-security-context
spec:
  runAsNonRoot: true
  runAsUser: 10001
  runAsGroup: 10001
  fsGroup: 10001
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
'''
                    
                    sh '''
                        kubectl apply -f security-policy.yaml
                        
                        kubectl set image deployment/my-app \
                            my-app=my-app:${BUILD_NUMBER}
                        
                        kubectl patch deployment my-app -p '{
                            "spec": {
                                "template": {
                                    "spec": {
                                        "securityContext": {
                                            "runAsNonRoot": true,
                                            "runAsUser": 10001,
                                            "runAsGroup": 10001,
                                            "fsGroup": 10001
                                        }
                                    }
                                }
                            }
                        }'
                        
                        kubectl rollout status deployment/my-app --timeout=300s
                    '''
                }
            }
        }
        
        stage('Runtime Security Testing') {
            steps {
                script {
                    sh '''
                        # OWASP ZAP security testing
                        docker run --rm -v $(pwd):/zap/wrk/:rw \
                            -t owasp/zap2docker-weekly \
                            zap-baseline.py \
                            -t http://my-app-service:8080 \
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
                // Security metrics collection
                sh '''
                    kubectl get pods -l app=my-app -o json | \
                        jq '.items[].spec.securityContext' > security-context-report.json
                '''
                archiveArtifacts artifacts: 'security-context-report.json'
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

### 6. Blue-Green Deployment Pipeline

```groovy
pipeline {
    agent any
    
    environment {
        APP_NAME = 'web-application'
        VERSION = "${BUILD_NUMBER}"
        NAMESPACE = 'production'
    }
    
    stages {
        stage('Build and Test') {
            steps {
                sh 'docker build -t ${APP_NAME}:${VERSION} .'
                sh 'docker run --rm ${APP_NAME}:${VERSION} npm test'
            }
        }
        
        stage('Deploy to Blue Environment') {
            steps {
                script {
                    // Deploy to blue environment
                    sh """
                        kubectl set image deployment/${APP_NAME}-blue \
                            ${APP_NAME}=${APP_NAME}:${VERSION} \
                            -n ${NAMESPACE}
                        
                        kubectl rollout status deployment/${APP_NAME}-blue \
                            -n ${NAMESPACE} --timeout=300s
                    """
                }
            }
        }
        
        stage('Test Blue Environment') {
            steps {
                script {
                    // Health check on blue environment
                    sh """
                        kubectl run test-blue-${BUILD_NUMBER} --rm -i --restart=Never \
                            --image=curlimages/curl \
                            -- curl -f http://${APP_NAME}-blue-service.${NAMESPACE}.svc.cluster.local:8080/health
                    """
                    
                    // Load test on blue environment
                    sh """
                        kubectl run load-test-blue-${BUILD_NUMBER} --rm -i --restart=Never \
                            --image=loadimpact/k6:latest \
                            --command -- k6 run --vus 10 --duration 2m \
                            -e BASE_URL=http://${APP_NAME}-blue-service.${NAMESPACE}.svc.cluster.local:8080 \
                            /scripts/load-test.js
                    """
                }
            }
        }
        
        stage('Switch Traffic to Blue') {
            input {
                message "Switch traffic to blue environment?"
                ok "Switch Traffic"
                parameters {
                    choice(
                        name: 'TRAFFIC_SPLIT',
                        choices: ['10', '25', '50', '100'],
                        description: 'Percentage of traffic to route to blue'
                    )
                }
            }
            steps {
                script {
                    def trafficSplit = params.TRAFFIC_SPLIT as Integer
                    def blueWeight = trafficSplit
                    def greenWeight = 100 - trafficSplit
                    
                    sh """
                        kubectl patch service ${APP_NAME}-service -p '{
                            "spec": {
                                "selector": {
                                    "app": "${APP_NAME}",
                                    "version": "blue"
                                }
                            }
                        }' -n ${NAMESPACE}
                    """
                    
                    // If using Istio for traffic splitting
                    if (trafficSplit < 100) {
                        writeFile file: 'virtual-service.yaml', text: """
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: ${APP_NAME}
  namespace: ${NAMESPACE}
spec:
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: ${APP_NAME}-blue-service
      weight: 100
  - route:
    - destination:
        host: ${APP_NAME}-blue-service
      weight: ${blueWeight}
    - destination:
        host: ${APP_NAME}-green-service
      weight: ${greenWeight}
"""
                        sh 'kubectl apply -f virtual-service.yaml'
                    }
                    
                    echo "Traffic split: ${blueWeight}% blue, ${greenWeight}% green"
                }
            }
        }
        
        stage('Monitor Blue Environment') {
            steps {
                script {
                    echo "Monitoring blue environment for 5 minutes..."
                    sleep(300) // Monitor for 5 minutes
                    
                    // Check error rates and response times
                    sh """
                        kubectl run monitor-${BUILD_NUMBER} --rm -i --restart=Never \
                            --image=curlimages/curl \
                            --command -- sh -c '
                                for i in \$(seq 1 60); do
                                    curl -w "%{http_code} %{time_total}\\n" -o /dev/null -s \
                                        http://${APP_NAME}-service.${NAMESPACE}.svc.cluster.local:8080/health
                                    sleep 5
                                done
                            '
                    """
                }
            }
        }
        
        stage('Complete Blue-Green Switch') {
            input {
                message "Complete the blue-green deployment?"
                ok "Complete Switch"
            }
            steps {
                script {
                    // Switch all traffic to blue
                    sh """
                        kubectl patch service ${APP_NAME}-service -p '{
                            "spec": {
                                "selector": {
                                    "app": "${APP_NAME}",
                                    "version": "blue"
                                }
                            }
                        }' -n ${NAMESPACE}
                    """
                    
                    // Scale down green environment
                    sh """
                        kubectl scale deployment ${APP_NAME}-green --replicas=0 -n ${NAMESPACE}
                    """
                    
                    // Rename deployments for next cycle
                    sh """
                        kubectl patch deployment ${APP_NAME}-green -p '{
                            "metadata": {"name": "${APP_NAME}-temp"}
                        }' -n ${NAMESPACE}
                        
                        kubectl patch deployment ${APP_NAME}-blue -p '{
                            "metadata": {"name": "${APP_NAME}-green"}
                        }' -n ${NAMESPACE}
                        
                        kubectl patch deployment ${APP_NAME}-temp -p '{
                            "metadata": {"name": "${APP_NAME}-blue"}
                        }' -n ${NAMESPACE}
                    """
                    
                    echo "Blue-green deployment completed successfully!"
                }
            }
        }
    }
    
    post {
        failure {
            script {
                // Rollback to green environment on failure
                sh """
                    kubectl patch service ${APP_NAME}-service -p '{
                        "spec": {
                            "selector": {
                                "app": "${APP_NAME}",
                                "version": "green"
                            }
                        }
                    }' -n ${NAMESPACE}
                """
                echo "Rolled back to green environment due to failure"
            }
        }
    }
}
```

### 7. Database Migration Pipeline

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
        DB_HOST = 'postgres.database.svc.cluster.local'
        DB_PORT = '5432'
        DB_NAME = 'myapp'
        DB_USER = credentials('db-username')
        DB_PASSWORD = credentials('db-password')
    }
    
    stages {
        stage('Backup Database') {
            steps {
                script {
                    def timestamp = new Date().format('yyyyMMdd-HHmmss')
                    sh """
                        kubectl run db-backup-${BUILD_NUMBER} --rm -i --restart=Never \
                            --image=postgres:13 \
                            --env="PGPASSWORD=${DB_PASSWORD}" \
                            --command -- pg_dump \
                            -h ${DB_HOST} \
                            -p ${DB_PORT} \
                            -U ${DB_USER} \
                            -d ${DB_NAME} \
                            --verbose \
                            --no-password > backup-${timestamp}.sql
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
                        kubectl run migration-test-${BUILD_NUMBER} --rm -i --restart=Never \
                            --image=migrate/migrate \
                            --env="DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable" \
                            --command -- migrate \
                            -source file://migrations \
                            -database \$DATABASE_URL \
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
                            kubectl run migration-forward-${BUILD_NUMBER} --rm -i --restart=Never \
                                --image=migrate/migrate \
                                --env="DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable" \
                                --command -- migrate \
                                -source file://migrations \
                                -database \$DATABASE_URL \
                                up
                        """
                    } else if (params.MIGRATION_TYPE == 'rollback' && params.TARGET_VERSION) {
                        sh """
                            kubectl run migration-rollback-${BUILD_NUMBER} --rm -i --restart=Never \
                                --image=migrate/migrate \
                                --env="DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=disable" \
                                --command -- migrate \
                                -source file://migrations \
                                -database \$DATABASE_URL \
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
                        kubectl run migration-verify-${BUILD_NUMBER} --rm -i --restart=Never \
                            --image=postgres:13 \
                            --env="PGPASSWORD=${DB_PASSWORD}" \
                            --command -- psql \
                            -h ${DB_HOST} \
                            -p ${DB_PORT} \
                            -U ${DB_USER} \
                            -d ${DB_NAME} \
                            -c "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 5;"
                    """
                    
                    // Run data integrity checks
                    sh """
                        kubectl run data-integrity-${BUILD_NUMBER} --rm -i --restart=Never \
                            --image=postgres:13 \
                            --env="PGPASSWORD=${DB_PASSWORD}" \
                            --command -- psql \
                            -h ${DB_HOST} \
                            -p ${DB_PORT} \
                            -U ${DB_USER} \
                            -d ${DB_NAME} \
                            -f integrity-checks.sql
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
                        kubectl set image deployment/myapp \
                            myapp=myapp:${BUILD_NUMBER} \
                            --record
                        
                        kubectl rollout status deployment/myapp --timeout=300s
                    """
                }
            }
        }
        
        stage('Post-Migration Tests') {
            steps {
                script {
                    sh """
                        kubectl run post-migration-tests-${BUILD_NUMBER} --rm -i --restart=Never \
                            --image=myapp-tests:latest \
                            --env="DATABASE_URL=postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}" \
                            --command -- npm run test:integration
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
                        kubectl run migration-emergency-rollback-${BUILD_NUMBER} --rm -i --restart=Never \
                            --image=postgres:13 \
                            --env="PGPASSWORD=${DB_PASSWORD}" \
                            --command -- sh -c "
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
// vars/deployToKubernetes.groovy
def call(Map config) {
    script {
        sh """
            helm upgrade --install ${config.name} ${config.chart} \
                --namespace ${config.namespace} \
                --set image.tag=${config.tag} \
                --set image.repository=${config.repository} \
                --wait --timeout=300s
        """
        
        // Health check
        sh """
            kubectl wait --for=condition=ready pod \
                -l app=${config.name} \
                -n ${config.namespace} \
                --timeout=300s
        """
    }
}

// Usage in Jenkinsfile:
// deployToKubernetes([
//     name: 'my-app',
//     chart: './helm/my-app',
//     namespace: 'production',
//     tag: BUILD_NUMBER,
//     repository: 'my-registry.com/my-app'
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
