# Jenkins - CI/CD Server

## Introduction

[Jenkins](https://www.jenkins.io/) is an open-source automation server that provides hundreds of plugins to support building, deploying and automating any project.

## Installation

### Using Docker

```bash
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins jenkins/jenkins:lts
```

### Using Docker with persistent volume

```bash
docker run -d -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  --name jenkins jenkins/jenkins:lts
```

## Jenkins CLI

### Download Jenkins CLI

```bash
# Download CLI jar from your Jenkins instance
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Or using curl
curl -O http://localhost:8080/jnlpJars/jenkins-cli.jar
```

### Authentication

```bash
# Using username and password
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:password <command>

# Using API token (recommended)
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:api_token <command>
```

## Job Management

### List all jobs

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token list-jobs
```

### Create job from XML

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token create-job new-job < job-config.xml
```

### Build a job

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token build job-name

# Build with parameters
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token build job-name -p PARAMETER=value
```

### Get job configuration

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token get-job job-name > job-config.xml
```

### Update job configuration

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token update-job job-name < new-job-config.xml
```

### Delete a job

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token delete-job job-name
```

### Copy a job

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token copy-job source-job new-job
```

## Build Management

### Get build information

```bash
# Get console output
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token console job-name

# Get specific build console output
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token console job-name 123
```

### Cancel build

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token cancel-quiet-down
```

## Node Management

### List nodes

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token list-nodes
```

### Create node

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token create-node node-name < node-config.xml
```

### Take node offline

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token offline-node node-name "Maintenance"
```

### Bring node online

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token online-node node-name
```

## Plugin Management

### List installed plugins

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token list-plugins
```

### Install plugin

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token install-plugin plugin-name
```

## System Management

### Restart Jenkins safely

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token safe-restart
```

### Reload configuration

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token reload-configuration
```

### Quiet down (prepare for shutdown)

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token quiet-down
```

### Get Jenkins version

```bash
java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token version
```

## Backup and Restore

### Backup Jenkins home

```bash
# Create backup of Jenkins home directory
tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/jenkins_home

# Using Docker volume backup
docker run --rm -v jenkins_home:/data -v $(pwd):/backup ubuntu tar -czf /backup/jenkins-backup.tar.gz -C /data .
```

### Restore Jenkins home

```bash
# Restore from backup
tar -xzf jenkins-backup.tar.gz -C /var/jenkins_home

# Using Docker volume restore
docker run --rm -v jenkins_home:/data -v $(pwd):/backup ubuntu tar -xzf /backup/jenkins-backup.tar.gz -C /data
```

## Pipeline Examples

### Basic Jenkinsfile

```groovy
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo 'Building...'
                sh 'make build'
            }
        }
        stage('Test') {
            steps {
                echo 'Testing...'
                sh 'make test'
            }
        }
        stage('Deploy') {
            steps {
                echo 'Deploying...'
                sh 'make deploy'
            }
        }
    }
}
```

### Pipeline with Docker

```groovy
pipeline {
    agent {
        docker {
            image 'node:16'
        }
    }

    stages {
        stage('Install') {
            steps {
                sh 'npm install'
            }
        }
        stage('Test') {
            steps {
                sh 'npm test'
            }
        }
    }
}
```

## Useful Aliases

```bash
# Add to your .bashrc or .zshrc
alias jenkins-cli='java -jar jenkins-cli.jar -s http://localhost:8080 -auth username:token'
alias jcli='jenkins-cli'

# Examples with alias
jcli list-jobs
jcli build my-job
jcli console my-job
```

## Troubleshooting

### Check Jenkins logs

```bash
# Docker container logs
docker logs jenkins

# Follow logs
docker logs -f jenkins
```

### Fix permission issues

```bash
# Fix Jenkins home permissions
sudo chown -R 1000:1000 /var/jenkins_home

# Docker permission fix
docker exec -u root jenkins chown -R jenkins:jenkins /var/jenkins_home
```
