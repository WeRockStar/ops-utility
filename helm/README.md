# Helm - Package Manager for Kubernetes

## Installation on MacOS

```bash
brew install helm
```

## Getting Started

```bash
helm --version

helm repo list

# list all installed releases
helm ls
```

## Add Helm Repository

```bash
helm repo add <REPO_NAME> <REPO_URL>

# example. Add Airbyte Helm Repository
helm repo add airbyte https://airbytehq.github.io/helm-charts
```

## Search Helm Repository

Search Helm repository for available charts. If no repository is specified, it will search all repositories.

```bash
helm search repo <REPO_NAME>

# example. Search Airbyte Helm Repository
helm search repo airbyte
```

## Install Helm Chart

```bash
helm install <RELEASE_NAME> <REPO_NAME>

# example. Install Airbyte Helm Chart
helm install airbyte airbyte/airbyte

# Specific namespace for install
helm install airbyte airbyte/airbyte --namespace airbyte

# nginx is a name of release, and specific chart version (not same version for app version)
helm install nginx bitnami/nginx --version 16.0.6

# show values of helm chart
helm show values bitnami/nginx
helm show values bitnami/nginx > values.yaml
```

Note: While installing Helm chart, you can specify the namespace where the chart will be installed. Moreover, you will see metadata of the chart, such as chart version, application version, revision, status, and so on.

![Helm Install Process](helm-install.png)
Written in [templates/NOTES.txt](https://github.com/bitnami/charts/blob/main/bitnami/nginx/templates/NOTES.txt)

## Upgrade Helm Chart

```bash
helm upgrade <RELEASE_NAME> <REPO_NAME>

# or install with upgrade
helm upgrade --install airflow apache-airflow/airflow

# update helm repository
helm repo update

# upgrade ngnix to latest version (nginx is a name of release)
helm upgrade nginx bitnami/nginx
```

## Uninstall Helm Release

```bash
helm uninstall <RELEASE_NAME>
```

## Revision History

```bash
helm history <RELEASE_NAME>

helm history nginx
```

## Rollback

```bash
helm rollback <RELEASE_NAME> <REVISION_NUMBER>

# example. Rollback to previous revision
helm rollback nginx 1

# check revision version
helm ls
```

Note: Helm rollback will create new revision.
