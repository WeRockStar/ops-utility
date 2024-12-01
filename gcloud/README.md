# Google Cloud CLI

## Why

Every time I use Google Cloud CLI, I have to search for the commands. So, I decided to write a simple guide for myself.

### Auth

List active account

```bash
gcloud auth list
```

Set the active account

```bash
gcloud config set account `<ACCOUNT>`
```

### Login to Google Cloud

```bash
gcloud auth login

# application default
gcloud auth application-default login

gcloud auth activate-service-account --key-file="SERVICE_ACCOUNT_KEY_FILE.json"
# example
gcloud auth activate-service-account --key-file="./sa.json"
```

### List the projects

```bash
gcloud projects list

# List project in core section
gcloud config list project

# Current project
gcloud config get-value project
```

### Set the project

```bash
gcloud config set project <project-id>
```

### Get GKE Credentials

```bash
gcloud container clusters get-credentials <NAME_OF_CLUSTER> --zone <LOCATION> --project <PROJECT_ID>

# Example
gcloud container clusters get-credentials <NAME_OF_CLUSTER> --zone asia-southeast1-a --project <PROJECT_ID>
```
