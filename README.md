# Terraform ECS Fargate - Modular Structure

This Terraform configuration provides a modular, production-ready setup for migrating Event Farm from Docker Swarm to AWS ECS Fargate.

## Structure

```
terraform/
├── environments/          # Environment-specific configurations
│   └── main/             # Production environment
│       ├── provider.tf
│       ├── variables.tf
│       ├── main.tf       # (to be created)
│       └── outputs.tf    # (to be created)
│
└── modules/              # Reusable modules
    ├── network/          # VPC and networking
    ├── security/         # Security groups
    ├── iam/              # IAM roles
    ├── monitoring/       # CloudWatch logs
    ├── ecr/              # ECR repositories
    └── ecs/
        ├── cluster/      # ECS cluster
        ├── task/         # Task definitions
        ├── service/      # ECS services (to be created)
        └── alb/          # Application Load Balancer (to be created)
```

## Quick Start

1. **Navigate to environment directory:**
   ```bash
   cd terraform/environments/main
   ```

2. **Create terraform.tfvars:**
   ```bash
   cp ../../terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan and Apply:**
   ```bash
   terraform plan
   terraform apply
   ```

## Modules

See `MODULAR_STRUCTURE.md` for detailed module documentation.

## Status

✅ **Completed:**
- Network module
- Security module
- IAM module
- Monitoring module
- ECR module
- ECS Cluster module
- ECS Task module

⏳ **In Progress:**
- ECS Service module
- ECS ALB module
- Environment main.tf configuration

## Documentation

- `MODULAR_STRUCTURE.md` - Complete module structure and design
- `STRUCTURE.md` - Detailed directory structure
- `environments/main/README.md` - Environment-specific documentation

