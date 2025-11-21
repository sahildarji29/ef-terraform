# Main Environment Configuration

This is the production/main environment configuration for the Event Farm ECS Fargate infrastructure.

## Structure

- `provider.tf` - Terraform and AWS provider configuration
- `variables.tf` - Input variables
- `main.tf` - Main configuration that calls all modules
- `outputs.tf` - Output values
- `terraform.tfvars` - Environment-specific values (gitignored)

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Fill in your environment-specific values
3. **Initialize Terraform:**
   ```bash
   terraform init
   ```
   This will configure Terraform to store state in S3 at `eventfarm/main/terraform.tfstate`
4. Run `terraform plan` to review changes
5. Run `terraform apply` to deploy

## State Management

This environment uses **centralized S3 backend** for state management:
- **S3 Bucket:** `eventfarm-terraform-state`
- **State Path:** `eventfarm/main/terraform.tfstate`
- **State Locking:** DynamoDB table `terraform-state-lock`
- **Encryption:** Enabled

The backend configuration is defined directly in `provider.tf`. This ensures:
- State is stored centrally in S3
- State locking prevents concurrent modifications
- Automatic backups and versioning via S3
- Team collaboration on the same state file

## Module Structure

The configuration uses the following modules:

- `modules/network` - VPC and subnet data sources
- `modules/security` - Security groups
- `modules/iam` - IAM roles
- `modules/monitoring` - CloudWatch logs
- `modules/ecs/cluster` - ECS cluster
- `modules/ecs/task` - Task definitions
- `modules/ecs/service` - ECS services
- `modules/ecs/alb` - Application Load Balancer

## Environment Variables

All environment variables should be stored in:
- AWS Systems Manager Parameter Store (recommended)
- AWS Secrets Manager (for sensitive data)

Update task definitions to reference these secrets.

