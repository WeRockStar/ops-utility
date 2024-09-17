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

# Secrets
kubectl get secrets

# Secret details (airflow-postgresql is the name of the secret)
kubectl get secret airflow-postgresql -oyaml

# Persistent Volume
kubectl get persistentvolumes
# or shorter
kubectl get pv

# Persistent Volume Claim
kubectl get persistentvolumeclaims
# or shorter
kubectl get pvc
```

Note: `echo <BASE64> | base64 -d` to decode the secret

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
