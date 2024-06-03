# Trivy

### Scan IaC

```bash {"id":"01HZE7CWD507G7WRYG0PEJPSY9"}
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