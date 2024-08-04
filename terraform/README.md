# Terraform

The collection of Terraform scripts.

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

```hcl
terraform plan

# plan with variable
terraform plan -var="XXXX=XXXX"
```

### Apply the Terraform

```hcl
terraform apply

# apply with variable
terraform apply -var="XXXX=XXXX"

# specific resource
terraform apply -target=<resource_name>

# specific module
terraform apply -target=module.<module_name>
```

### Destroy the Terraform

```hcl
terraform destroy

# destroy specific resource
terraform destroy -target=<resource_name>
```

### Terraform Commands

```hcl
terraform --help
```

### Terraform State

```hcl
terraform state list
terraform state show <resource_name>

# remove the resource from the state
terraform state rm <resource_name>
```

## Terraform Format

```hcl
terraform fmt

# format specific file
terraform fmt <file_name>

# recursive format
terraform fmt -recursive
```

## Terraform Validate

```hcl
terraform validate
```

## Terraform Workspace

```hcl
terraform workspace list
terraform workspace new <workspace_name>
terraform workspace select <workspace_name>
terraform workspace delete <workspace_name>
```
