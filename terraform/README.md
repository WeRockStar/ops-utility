# Terraform

## Installation

```bash
# Install the HashiCorp tap
brew tap hashicorp/tap

# Install the Terraform
brew install hashicorp/tap/terraform

# Verify the installation
terraform --version
terraform -help
```

### Intialize Terraform

```hcl
terraform init
```

### Plan the Terraform

```terraform
terraform plan

# plan with variable
terraform plan -var="XXXX=XXXX"
```

### Apply the Terraform

```terraform
terraform apply

# apply with variable
terraform apply -var="XXXX=XXXX"

# specific resource
terraform apply -target=<resource_name>
```

### Destroy the Terraform

```terraform
terraform destroy

# destroy specific resource
terraform destroy -target=<resource_name>
```

### Terraform Commands

```terraform
terraform --help
```

### Terraform State

```terraform
terraform state list
terraform state show <resource_name>
```
