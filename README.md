# Terraform ECS Fargate Setup

This Terraform configuration migrates the Event Farm platform from Docker Swarm to AWS ECS Fargate, using the existing VPC infrastructure.

## Architecture

- **ECS Fargate Cluster**: Container orchestration
- **Application Load Balancer (ALB)**: External traffic routing
- **Service Discovery**: Internal service communication (optional)
- **Auto Scaling**: Automatic scaling based on CPU/memory
- **CloudWatch Logs**: Centralized logging
- **Security Groups**: Network isolation

## Prerequisites

1. **Terraform** >= 1.0
2. **AWS CLI** configured with appropriate credentials
3. **Existing VPC** with public and private subnets
4. **Docker images** pushed to ECR or Docker Hub
5. **ACM Certificate** (or create one via Terraform)

## Quick Start

### 1. Configure Variables

Copy the example variables file and customize:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
cluster_name = "blue"
environment  = "prod"
vpc_id       = "vpc-43a1cc24"  # Your existing VPC ID
public_subnet_ids = ["subnet-xxx", "subnet-yyy"]
private_subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc", "subnet-ddd"]
```

### 2. Get VPC and Subnet IDs

Find your existing VPC and subnet IDs:

```bash
# List VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table

# List subnets in your VPC
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-43a1cc24" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

### 3. Initialize Terraform

```bash
cd terraform
terraform init
```

### 4. Plan Deployment

Review what will be created:

```bash
terraform plan
```

### 5. Apply Configuration

Deploy the infrastructure:

```bash
terraform apply
```

## Configuration Files

- `main.tf` - Main configuration, ECS cluster, CloudWatch logs
- `variables.tf` - Input variables
- `outputs.tf` - Output values
- `task-definitions.tf` - ECS task definitions for all services
- `services.tf` - ECS services
- `alb.tf` - Application Load Balancer configuration
- `security-groups.tf` - Security groups
- `autoscaling.tf` - Auto scaling policies
- `terraform.tfvars.example` - Example variables file

## Services Created

1. **app** - Main application service (nginx + PHP-FPM)
2. **api2** - API service
3. **process-job-worker** - Background job workers
4. **canvas** - Canvas service
5. **urltopng** - URL to PNG service
6. **gearman-server** - Gearman job queue server
7. **scheduler** - Job scheduler (Kala)

## Environment Variables

Environment variables should be managed via:

1. **AWS Systems Manager Parameter Store** (recommended)
2. **AWS Secrets Manager** (for sensitive data)
3. **ECS Task Definition** (for non-sensitive config)

### Example: Using Parameter Store

```bash
# Store environment variables
aws ssm put-parameter \
  --name "/ecs/${cluster_name}/MYSQL_HOST" \
  --value "184.72.251.118" \
  --type "String"

aws ssm put-parameter \
  --name "/ecs/${cluster_name}/MYSQL_PASSWORD" \
  --value "your-password" \
  --type "SecureString"
```

Then update `task-definitions.tf` to use secrets:

```hcl
secrets = [
  {
    name      = "MYSQL_HOST"
    valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/ecs/${var.cluster_name}/MYSQL_HOST"
  },
  {
    name      = "MYSQL_PASSWORD"
    valueFrom = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/ecs/${var.cluster_name}/MYSQL_PASSWORD"
  }
]
```

## Service Discovery

If enabled, services can communicate using DNS names:

- `api2.eventfarm.local`
- `gearman-server.eventfarm.local`
- `canvas.eventfarm.local`
- `urltopng.eventfarm.local`
- `scheduler.eventfarm.local`

Update your application code to use these DNS names instead of Docker service names.

## Load Balancer Routing

The ALB routes traffic based on host headers:

- `app.eventfarm.com` → app service
- `api.eventfarm.com` → api2 service
- `login.eventfarm.com` → app service
- `*.eventfarm.com` → app service

## Auto Scaling

Auto scaling is configured for:
- **app** service: 2-10 tasks (CPU/Memory based)
- **api2** service: 2-10 tasks (CPU/Memory based)
- **worker** service: 5-50 tasks (CPU based)

Adjust thresholds in `autoscaling.tf` or via variables.

## Security Groups

Three security groups are created:

1. **ALB Security Group** - Allows HTTP/HTTPS from internet
2. **ECS Tasks Security Group** - Allows traffic from ALB, internal communication
3. **ECS Internal Security Group** - For workers, gearman, scheduler

Security group rules are automatically created for:
- RDS/MySQL access (if `database_security_group_id` provided)
- MongoDB access (if `mongodb_security_group_id` provided)

## SSL/TLS Certificate

### Option 1: Use Existing Certificate

```hcl
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/xxxxx"
```

### Option 2: Create New Certificate

Terraform will create a new certificate. You'll need to validate it:

1. Get validation records:
```bash
terraform output acm_certificate_arn
aws acm describe-certificate --certificate-arn <arn>
```

2. Add DNS validation records to your domain

3. Wait for validation (or use `aws_acm_certificate_validation` resource)

## Updating Services

### Update Task Definition

1. Update image version in `terraform.tfvars`:
```hcl
app_image = "membersuite/app:new-version"
```

2. Apply changes:
```bash
terraform apply
```

### Scale Services

Update desired count:

```hcl
app_scale = 6
worker_scale = 30
```

Or use AWS Console/CLI:

```bash
aws ecs update-service \
  --cluster blue-cluster \
  --service blue-app \
  --desired-count 6
```

## Monitoring

### CloudWatch Logs

All services log to CloudWatch:

- `/ecs/{cluster_name}/app`
- `/ecs/{cluster_name}/api2`
- `/ecs/{cluster_name}/process-job-worker`
- etc.

View logs:

```bash
aws logs tail /ecs/blue-cluster/app --follow
```

### Container Insights

Container Insights is enabled on the cluster. View metrics in CloudWatch Console.

## Troubleshooting

### Service Not Starting

1. Check CloudWatch logs:
```bash
aws logs tail /ecs/{cluster_name}/{service-name} --follow
```

2. Check service events:
```bash
aws ecs describe-services \
  --cluster {cluster_name}-cluster \
  --services {cluster_name}-app
```

3. Check task status:
```bash
aws ecs list-tasks --cluster {cluster_name}-cluster --service-name {cluster_name}-app
aws ecs describe-tasks --cluster {cluster_name}-cluster --tasks <task-id>
```

### Health Check Failures

1. Verify health check path is correct in task definition
2. Check security group rules allow traffic
3. Verify container is listening on correct port

### Service Discovery Not Working

1. Verify service discovery is enabled
2. Check DNS namespace exists:
```bash
aws servicediscovery list-namespaces
```

3. Verify services are registered:
```bash
aws servicediscovery list-services --filters Name=NAMESPACE_ID,Values=<namespace-id>
```

## Migration Checklist

- [ ] Configure `terraform.tfvars` with your values
- [ ] Verify VPC and subnet IDs
- [ ] Set up Parameter Store/Secrets Manager for environment variables
- [ ] Update task definitions with all required environment variables
- [ ] Configure ACM certificate (existing or new)
- [ ] Update DNS records to point to ALB
- [ ] Test service discovery DNS resolution
- [ ] Update application code for new service discovery names
- [ ] Test health checks
- [ ] Configure auto scaling thresholds
- [ ] Set up CloudWatch alarms
- [ ] Test failover scenarios
- [ ] Update CI/CD pipelines

## Cost Optimization

- Use Fargate Spot for non-critical services (workers)
- Right-size CPU/memory based on actual usage
- Enable auto scaling to scale down during low traffic
- Use CloudWatch Logs retention policies
- Consider Reserved Capacity for predictable workloads

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all ECS services, ALB, and related resources!

## Support

For issues or questions:
1. Check CloudWatch logs
2. Review ECS service events
3. Verify security group rules
4. Check task definition configuration

## Next Steps

After successful deployment:

1. **Update DNS**: Point domains to ALB DNS name
2. **Monitor**: Set up CloudWatch alarms
3. **Optimize**: Adjust CPU/memory based on metrics
4. **Scale**: Fine-tune auto scaling policies
5. **Migrate**: Gradually move traffic from Docker Swarm to ECS

