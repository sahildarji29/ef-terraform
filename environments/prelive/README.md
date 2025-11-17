# Prelive Environment Configuration

This is the prelive environment configuration for the Event Farm ECS Fargate infrastructure.

## Differences from Main

- **Cluster Name**: `teal` (instead of `blue`)
- **Environment**: `prelive` (instead of `prod`)
- **Scaling**: Lower scale (10 workers vs 20)
- **Domains**: `prelive-eventfarm.com` subdomain
- **Service Discovery Namespace**: `prelive-eventfarm.local`

## Usage

1. Copy `main.tf` from `environments/main/main.tf`
2. Create `terraform.tfvars` with prelive-specific values
3. Run `terraform init`, `terraform plan`, `terraform apply`

## Configuration

See `environments/main/README.md` for general setup instructions.

