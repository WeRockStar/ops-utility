# Trivy

## Introduction

[Trivy](https://trivy.dev/) is a simple and comprehensive vulnerability scanner for containers and other artifacts.

### Scan IaC

```bash
trivy config --severity=CRITICAL,HIGH ./
```

### Scan Images

```bash
trivy image python:3.4-alpine

# Scan with severity
trivy image --severity HIGH,CRITICAL alpine:3.15

# Scan image from tar file
trivy image --input ruby-3.1.tar
```
