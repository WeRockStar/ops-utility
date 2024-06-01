# Terraform


### Installation

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
```hcl
terraform plan

<!-- plan with variable -->
terraform plan -var="XXXX=XXXX"
```

### Apply the Terraform
```hcl
terraform apply

<!-- apply with variable -->
terraform apply -var="XXXX=XXXX"
```

### Destroy the Terraform
```hcl
terraform destroy
```

### Terraform Commands
```hcl
terraform --help
```

### Terraform State
```hcl
terraform state list
terraform state show <resource_name>
```