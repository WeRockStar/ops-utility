# Gitlab CI/CD Pipeline

## Overview

```yaml
stages:
  - build
  - test
  - deploy

build:
    stage: build
    script:
        - echo "Building the app"

test:
    stage: test
    script:
        - echo "Testing the app"

deploy:
    stage: deploy
    script:
        - echo "Deploying the app"
```

## Pipeline at Scale

- Hidden Jobs

## Build Docker Images

```yaml
stages:
    - plain-docker
    - kaniko

plain-docker:
    stage: plain-docker
    script:
        - docker build -t plain-docker-image .

kaniko:
    stage: kaniko
    image: gcr.io/kaniko-project/executor:latest
    before_script:
        - echo $SERVICE_ACCOUNT_JSON > sa.json
        - export GOOGLE_APPLICATION_CREDENTIALS=sa.json
    script:
        - /kaniko/executor --context "$CI_PROJECT_DIR" --dockerfile "$CI_PROJECT_DIR/Dockerfile" --destination "$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA"
```
