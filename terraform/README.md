# Terraform

The collection of Terraform scripts.

## Table of Contents

- [Installation](#installation)
- [Intialize Terraform](#intialize-terraform)
- [Plan the Terraform](#plan-the-terraform)
- [Apply the Terraform](#apply-the-terraform)
- [Destroy the Terraform](#destroy-the-terraform)
- [Terraform Commands](#terraform-commands)
- [Terraform State](#terraform-state)
- [Terraform Format](#terraform-format)
- [Terraform Validate](#terraform-validate)
- [Terraform Workspace](#terraform-workspace)
- [Managing Terraform Client Versions](#managing-terraform-client-versions)
- [Tools](#tools)

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
# check the format
terraform fmt -check

# format the files
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

## Managing Terraform Client Versions

Use [tfenv](https://github.com/tfutils/tfenv) to manage multiple versions of Terraform easily.
```bash
# Install specific Terraform version
tfenv install <version>

# Use/switch to specific Terraform version
tfenv use <version>

# List all installed Terraform versions
tfenv list

# Uninstall specific Terraform version
tfenv uninstall <version>
```

## Tools

- [TFLint](https://github.com/terraform-linters/tflint)
- [Open Policy Agent](https://github.com/open-policy-agent/opa)
- [Terrascan](https://github.com/tenable/terrascan)
- [Checkov](https://github.com/bridgecrewio/checkov)
- [Terratest](https://github.com/gruntwork-io/terratest)
- [Terragrunt](https://github.com/gruntwork-io/terragrunt)
- [Infracost](https://github.com/infracost/infracost)
- [Terratag](https://github.com/env0/terratag)
- [Terraform-docs](https://github.com/terraform-docs/terraform-docs/)
- [Terraform-Switcher](https://github.com/warrensbox/terraform-switcher)
