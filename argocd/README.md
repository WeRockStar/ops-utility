# ArgoCD

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.

## Login

```bash
argocd login <ARGOCD_SERVER> --username <ARGOCD_USERNAME> --password <ARGOCD_PASSWORD>

argocd login localhost:8080 --username admin --password admin
```

## List Applications

```bash
argocd app list
```

## Create Application

```bash
argocd app create <APP_NAME> --repo <REPO_URL> --path <PATH_TO_MANIFEST> --dest-server <DESTINATION_SERVER> --dest-namespace <DESTINATION_NAMESPACE>
```
