# Kubernetes

## Installation

```bash
# Install the Kubernetes CLI
brew install kubectl
```

## Getting Started

```bash
kubectl version
```

## Getting Informations

```bash
# Node
kubectl get nodes

# Pods
kubectl get pods

# Services
kubectl get services

# Deployments
kubectl get deployments
```

## Apply/Delete the Configuration

```bash
kubectl apply -f <file_name>

kubectl delete -f <file_name>
```

## Namespace

```bash
# Create a namespace
kubectl create namespace <namespace_name>

# Get the namespace
kubectl get namespace

# View Pod in the namespace
kubectl get pods -n <namespace_name>
```
