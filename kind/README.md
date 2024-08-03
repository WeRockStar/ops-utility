# [Kind](https://github.com/kubernetes-sigs/kind) - Local clusters for testing Kubernetes

## Installation

If can find more information on the [official website](https://kind.sigs.k8s.io/docs/user/quick-start#installation).

```bash
go install sigs.k8s.io/kind@v0.23.0
```

## Getting Started

### Create a cluster

Create a cluster with configuration file.

Cluster Name: `kind-cluster`

```bash
kind create cluster --name kind-cluster --config kind-cluster.yaml
```

### Working with Kubernetes via kubectl

Get the Kubernetes context.

```bash
kubectl cluster-info --context kind-cluster
```

View the nodes in the cluster.

```bash
kubectl get nodes
```
