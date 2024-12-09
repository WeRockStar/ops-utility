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

### Scan Filesystem

```bash
trivy fs --severity HIGH,CRITICAL .
```

### Options (I'm using frequently)

- `--severity` - Specify the severities of vulnerabilities to be displayed
- `--format` - Specify the output format (table, json, template, github)
- `--skip-dirs` - Skip the specified directories
- `--skip-files` - Skip the specified files
