# Production Environment Configuration

Production-ready Terraform configuration for deploying containerized applications on AWS ECS Fargate.

## 📁 File Structure

```
environments/main/
├── provider.tf              # Terraform backend and AWS provider configuration
├── variables.tf             # Variable definitions with descriptions
├── main.tf                  # Main infrastructure orchestration
├── ssm-parameters.tf        # Environment variables and secrets (SSM Parameter Store)
├── outputs.tf               # Output values (ALB URLs, service endpoints, etc.)
├── terraform.tfvars.example # Configuration template (safe to commit)
└── terraform.tfvars        # Your actual values (gitignored - never commit)
```

## 🚀 Quick Start

### 1. Initial Setup

```bash
# Navigate to environment directory
cd environments/main

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your actual values
# (VPC IDs, domains, database credentials, etc.)
```

### 2. Initialize Terraform

```bash
terraform init
```

This configures:
- Remote state backend (S3)
- State locking (DynamoDB)
- AWS provider plugins

### 3. Review and Deploy

```bash
# Review planned changes
terraform plan

# Apply configuration
terraform apply
```

## 🔐 State Management

**Centralized S3 Backend:**
- **Bucket:** `eventfarm-terraform-state`
- **State Path:** `eventfarm/main/terraform.tfstate`
- **Locking:** DynamoDB table `terraform-state-lock`
- **Encryption:** Enabled at rest

**Benefits:**
- ✅ Centralized state storage
- ✅ State locking prevents conflicts
- ✅ Version history via S3 versioning
- ✅ Team collaboration on shared state

## 🏗️ Infrastructure Components

### Network Layer
- **VPC:** Uses existing VPC (no VPC creation)
- **Subnets:** Public (ALB) and Private (ECS tasks)
- **Multi-AZ:** High availability across availability zones

### Security Layer
- **Security Groups:** Service-specific network isolation
- **IAM Roles:** Least privilege access patterns
- **Secrets Management:** SSM Parameter Store with encryption

### Compute Layer
- **ECS Fargate:** Serverless container orchestration
- **Services:** 7 microservices (app, api2, worker, canvas, urltopng, gearman, scheduler)
- **Auto Scaling:** CPU/memory-based automatic scaling

### Application Layer
- **ALB:** Application Load Balancer with HTTP/HTTPS
- **Target Groups:** Service-specific routing
- **Service Discovery:** Internal DNS-based communication

### Monitoring Layer
- **CloudWatch Logs:** Centralized logging per service
- **Log Retention:** Configurable retention periods
- **Container Insights:** ECS performance monitoring

## 🔑 Environment Variables & Secrets

**All managed in:** `ssm-parameters.tf`

**Features:**
- Centralized management
- Encrypted secrets (SecureString)
- Service-specific mappings
- Easy to add new variables

**See:** `ssm-parameters.tf` for details on adding new environment variables.

## 📊 Module Architecture

This environment uses modular, reusable components:

| Module | Purpose | Location |
|--------|---------|----------|
| `network` | VPC and subnet configuration | `../../modules/network` |
| `security` | Security groups and rules | `../../modules/security` |
| `iam` | IAM roles and policies | `../../modules/iam` |
| `monitoring` | CloudWatch log groups | `../../modules/monitoring` |
| `ecs/cluster` | ECS cluster with service discovery | `../../modules/ecs/cluster` |
| `ecs/task` | Task definitions | `../../modules/ecs/task` |
| `ecs/service` | ECS services with auto-scaling | `../../modules/ecs/service` |
| `ecs/alb` | Application Load Balancer | `../../modules/ecs/alb` |

## ⚙️ Configuration

### Required Variables

- `vpc_id` - Existing VPC ID
- `public_subnet_ids` - Public subnet IDs for ALB
- `private_subnet_ids` - Private subnet IDs for ECS tasks
- `domain` - Main application domain
- `database_host` - Database endpoint
- `database_password` - Database password (sensitive)

### Optional Variables

- `acm_certificate_arn` - SSL certificate (for HTTPS)
- `dockerhub_secret_arn` - Existing Docker Hub secret
- `enable_auto_scaling` - Enable auto-scaling (default: true)
- `log_retention_days` - CloudWatch log retention (default: 30)

See `variables.tf` for complete variable documentation.

## 🔒 Security Best Practices

1. ✅ **Never commit `terraform.tfvars`** - Contains sensitive values (gitignored)
2. ✅ **Use SSM SecureString** - All passwords/tokens encrypted
3. ✅ **Least privilege IAM** - Services only access needed resources
4. ✅ **Network isolation** - Tasks in private subnets
5. ✅ **Security groups** - Service-specific network rules
6. ✅ **Encrypted state** - S3 backend with encryption

## 📝 Notes

- **terraform.tfvars** is gitignored - contains your actual secrets
- **State file** stored remotely in S3 (encrypted)
- **Secrets** should be rotated regularly
- **Resource sizing** should be adjusted based on load testing
- **CIDR blocks** should be restricted in production (not 0.0.0.0/0)

## 🔄 Workflow

1. **Modify configuration** in `main.tf` or modules
2. **Update variables** in `terraform.tfvars` (if needed)
3. **Review changes:** `terraform plan`
4. **Apply changes:** `terraform apply`
5. **Verify deployment** via AWS Console or outputs

## 📚 Additional Documentation

- **Root README.md** - Overall project documentation
- **MODULAR_STRUCTURE.md** - Module architecture details
- **STRUCTURE.md** - Complete directory structure

