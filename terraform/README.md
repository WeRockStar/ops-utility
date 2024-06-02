# Terraform

### Installation

```bash {"id":"01HZBZ6B5BRJDHW3F4Z88BG346"}
# Install the HashiCorp tap
brew tap hashicorp/tap

# Install the Terraform
brew install hashicorp/tap/terraform

# Verify the installation
terraform --version
terraform -help
```

### Intialize Terraform

```hcl {"id":"01HZBZ6B5BRJDHW3F4ZA8W0MQQ"}
terraform init
```

### Plan the Terraform

```terraform {"id":"01HZBZ6B5BRJDHW3F4ZBE81EVZ"}
terraform plan

# plan with variable
terraform plan -var="XXXX=XXXX"
```

### Apply the Terraform

```terraform {"id":"01HZBZ6B5BRJDHW3F4ZEN0884S"}
terraform apply

# apply with variable
terraform apply -var="XXXX=XXXX"
```

### Destroy the Terraform

```terraform {"id":"01HZBZ6B5BRJDHW3F4ZJFBJY7M"}
terraform destroy
```

### Terraform Commands

```terraform {"id":"01HZBZ6B5BRJDHW3F4ZKK25K3G"}
terraform --help
```

### Terraform State

```terraform {"id":"01HZBZ6B5BRJDHW3F4ZPCS76TZ"}
terraform state list
terraform state show <resource_name>
```