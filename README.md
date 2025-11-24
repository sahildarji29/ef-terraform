# Event Farm - AWS ECS Fargate Infrastructure


## Architecture Overview

This infrastructure provides a complete container orchestration platform on AWS:

- **ECS Fargate** - Serverless container orchestration
- **Application Load Balancer** - High-availability traffic distribution
- **AWS Service Discovery** - Internal service-to-service communication
- **SSM Parameter Store** - Centralized environment variable and secret management
- **CloudWatch Logs** - Centralized logging and monitoring
- **Auto Scaling** - Automatic scaling based on demand
- **VPC Networking** - Secure network isolation

## Project Structure

```
ef-terraform/
├── environments/              # Environment-specific configurations
│   ├── main/                  # Production environment
│   │   ├── provider.tf        # Terraform backend and AWS provider
│   │   ├── variables.tf       # Variable definitions
│   │   ├── main.tf            # Main infrastructure orchestration
│   │   ├── ssm-parameters.tf  # Environment variables and secrets (SSM)
│   │   ├── outputs.tf         # Output values
│   │   ├── terraform.tfvars.example  # Configuration template
│   │   └── README.md          # Environment-specific docs
│
└── modules/                   # Reusable Terraform modules
    ├── network/              # VPC and networking resources
    ├── security/             # Security groups and rules
    ├── iam/                  # IAM roles and policies
    ├── monitoring/           # CloudWatch logs
    ├── ecr/                  # ECR repositories (optional)
    └── ecs/
        ├── cluster/          # ECS cluster configuration
        ├── task/             # Task definitions
        ├── service/          # ECS services with auto-scaling
        └── alb/              # Application Load Balancer
```

## Quick Start

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- Existing VPC and subnets in your AWS account

### Initial Setup

1. **Clone and navigate to environment:**
   ```bash
   cd environments/main
   ```

2. **Create configuration file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars` with your values:**
   - VPC and subnet IDs
   - Domain names
   - Database credentials
   - Container image names
   - Resource sizing

4. **Initialize Terraform:**
   ```bash
   terraform init
   ```

5. **Review planned changes:**
   ```bash
   terraform plan
   ```

6. **Apply configuration:**
   ```bash
   terraform apply
   ```

## Security & Secrets Management

### Environment Variables & Secrets

All environment variables and secrets are managed via **AWS SSM Parameter Store**:

- **Location**: `environments/main/ssm-parameters.tf`
- **Path Pattern**: `/eventfarm/{environment}/{cluster_name}/{VAR_NAME}`
- **Types**: 
  - `SecureString` - For passwords, tokens, API keys (encrypted)
  - `String` - For non-sensitive configuration

### Adding New Environment Variables

1. **Add parameter definition** in `ssm-parameters.tf`:
   ```hcl
   "NEW_VAR" = {
     value       = var.new_var_value
     type        = "SecureString"  # or "String"
     description = "Description of the variable"
   }
   ```

2. **Add to service mapping** (which services need it):
   ```hcl
   app_parameter_keys = [
     # ... existing ...
     "NEW_VAR",
   ]
   ```

3. **Apply changes:**
   ```bash
   terraform plan && terraform apply
   ```

### Secret Management Best Practices

-  **Never commit `terraform.tfvars`** - Already gitignored
-  **Use SecureString** for all sensitive data
-  **Rotate secrets regularly** - Update in AWS Console/CLI
-  **Least privilege IAM** - Services only access needed secrets
-  **Audit logging** - CloudTrail tracks all SSM access

## Infrastructure Components

### Network Layer
- Uses existing VPC (no VPC creation)
- Public subnets for ALB
- Private subnets for ECS tasks
- Security groups for network isolation

### Compute Layer
- **ECS Fargate** - Serverless containers
- **Multiple Services**:
  - App service (main application)
  - API2 service (API endpoints)
  - Worker service (background jobs)
  - Canvas service (image processing)
  - URL to PNG service (screenshot generation)
  - Gearman server (job queue)
  - Scheduler service (cron jobs)

### Application Layer
- **Application Load Balancer** - HTTP/HTTPS traffic distribution
- **Target Groups** - Service-specific routing
- **Service Discovery** - Internal DNS-based service communication
- **Auto Scaling** - CPU/memory-based scaling

### Security Layer
- **IAM Roles** - Least privilege access
- **Security Groups** - Network-level security
- **SSM Parameter Store** - Encrypted secrets
- **Secrets Manager** - Docker Hub credentials

### Monitoring Layer
- **CloudWatch Logs** - Centralized logging
- **Log Groups** - Per-service log aggregation
- **Configurable Retention** - Adjustable log retention periods