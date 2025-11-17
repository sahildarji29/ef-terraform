# Terraform Modular Structure

## Final Structure

```
terraform/
├── environments/
│   ├── main/                    # Production environment
│   │   ├── main.tf              # Calls all modules
│   │   ├── provider.tf          # Provider configuration
│   │   ├── variables.tf         # Environment-specific variables
│   │   ├── outputs.tf           # Environment outputs
│   │   └── terraform.tfvars      # Environment values (gitignored)
│   │
│   ├── prelive/                 # Prelive environment
│   │   └── ... (same structure)
│   │
│   └── dev/                     # Development environment
│       └── ... (same structure)
│
└── modules/
    ├── network/                 # VPC and Networking
    │   ├── main.tf              # Data sources for existing VPC
    │   ├── subnets.tf           # Subnet data sources
    │   ├── nat.tf               # NAT Gateway (if needed)
    │   ├── routes.tf            # Route tables
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── security/                # Security Groups
    │   ├── main.tf              # Main security group logic
    │   ├── alb.tf                # ALB security group
    │   ├── ecs.tf                # ECS tasks security group
    │   ├── internal.tf          # Internal services security group
    │   ├── rules.tf              # Security group rules
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── iam/                      # IAM Roles and Policies
    │   ├── ecs-execution.tf      # ECS execution role
    │   ├── ecs-task.tf           # ECS task role
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── monitoring/               # CloudWatch and Logging
    │   ├── logs.tf               # CloudWatch log groups
    │   ├── alarms.tf             # CloudWatch alarms (optional)
    │   ├── variables.tf
    │   └── outputs.tf
    │
    ├── ecr/                      # ECR Repositories
    │   ├── main.tf               # ECR repositories
    │   ├── lifecycle.tf          # Lifecycle policies
    │   ├── variables.tf
    │   └── outputs.tf
    │
    └── ecs/
        ├── cluster/              # ECS Cluster
        │   ├── main.tf
        │   ├── service-discovery.tf
        │   ├── variables.tf
        │   └── outputs.tf
        │
        ├── task/                 # Task Definitions
        │   ├── main.tf           # Task definition logic
        │   ├── app.tf             # App task definition
        │   ├── api2.tf            # API2 task definition
        │   ├── worker.tf          # Worker task definitions
        │   ├── services.tf       # Other service task definitions
        │   ├── variables.tf
        │   └── outputs.tf
        │
        ├── service/              # ECS Services
        │   ├── main.tf           # Service logic
        │   ├── app.tf            # App service
        │   ├── api2.tf           # API2 service
        │   ├── workers.tf        # Worker services
        │   ├── internal.tf       # Internal services
        │   ├── autoscaling.tf     # Auto scaling
        │   ├── variables.tf
        │   └── outputs.tf
        │
        └── alb/                  # Application Load Balancer
            ├── main.tf           # ALB resource
            ├── target-groups.tf  # Target groups
            ├── listeners.tf      # Listeners and rules
            ├── s3-logs.tf        # S3 bucket for logs
            ├── certificate.tf    # ACM certificate
            ├── variables.tf
            └── outputs.tf
```

## Module Design Principles

1. **Single Responsibility**: Each module has one clear purpose
2. **Reusability**: Modules can be used across environments
3. **Composability**: Modules can be combined easily
4. **Testability**: Each module can be tested independently
5. **Documentation**: Each module has clear inputs/outputs

## Module Dependencies

```
network
  ├── security (depends on network)
  │   └── ecs/alb (depends on security, network)
  │
  ├── iam
  │   └── ecs/cluster (depends on iam, monitoring)
  │       └── ecs/task (depends on iam, monitoring)
  │           └── ecs/service (depends on cluster, task, alb, security)
  │
  └── monitoring
      └── ecs/cluster (depends on monitoring)
```

## Benefits

✅ **Environment Isolation**: Each environment is self-contained
✅ **Code Reuse**: Modules shared across environments
✅ **Easy Updates**: Update module once, affects all environments
✅ **Team Collaboration**: Multiple teams can work on different modules
✅ **Testing**: Test modules independently before integration
✅ **Scalability**: Easy to add new environments or services

