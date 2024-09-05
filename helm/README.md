# Helm - Package Manager for Kubernetes

## Installation on MacOS

```bash
brew install helm
```

## Getting Started

```bash
helm --version

helm repo list
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
```

## Upgrade Helm Chart

```bash
helm upgrade <RELEASE_NAME> <REPO_NAME>

# or install with upgrade
helm upgrade --install airflow apache-airflow/airflow

# update helm repository
helm repo update
```

## Uninstall Helm Chart

```bash
helm uninstall <RELEASE_NAME>
```
