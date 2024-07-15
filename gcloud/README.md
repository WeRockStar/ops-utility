# Google Cloud CLI

### Login to Google Cloud

```bash
gcloud auth login

# application default
gcloud auth application-default login
```

### List the projects

```bash {"id":"01HZBZHYK70RX58KDCSJ022VDT"}
gcloud projects list

# List project in core section
gcloud config list project
```

### Set the project

```bash {"id":"01HZBZHYK70RX58KDCSEWS1B9H"}
gcloud config set project <project-id>
```

### Get GKE Credentials

```bash
gcloud container clusters get-credentials <NAME_OF_CLUSTER> --zone <LOCATION> --project <PROJECT_ID>

# Example
gcloud container clusters get-credentials <NAME_OF_CLUSTER> --zone asia-southeast1-a --project <PROJECT_ID>
```
