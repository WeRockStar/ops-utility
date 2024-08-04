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

```yaml
stages:
  - deploy-dev
  - deploy-prod

.deploy:
    image: hashicorp/terraform:1.9.3
    before_script:
        - terraform init

deploy-dev:
    stage: deploy-dev
    extends: .deploy
    script:
        - terraform apply -var="env=dev"

deploy-prod:
    stage: deploy-prod
    extends: .deploy
    script:
        - terraform apply -var="env=prod"
```

- Include CI templates

`Jobs/Deploy.yml`

```yaml
.deploy:
    image: hashicorp/terraform:1.9.3
    before_script:
        - terraform init
```

`gitlab-ci.yml`

```yaml
# include: "Jobs/Deploy.yml"

include:
    - template: Jobs/Deploy.yml

stages:
    - deploy-dev
    - deploy-prod

deploy-dev:
    stage: deploy-dev
    extends: .deploy
    script:
        - terraform apply -var="env=dev"

deploy-prod:
    stage: deploy-prod
    extends: .deploy
    script:
        - terraform apply -var="env=prod"
```

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
