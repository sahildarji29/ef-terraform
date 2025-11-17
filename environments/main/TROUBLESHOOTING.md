# Troubleshooting Guide

## ACM Certificate Issues

### Error: "The certificate must have a fully-qualified domain name, a supported signature, and a supported key size"

**Cause**: The ACM certificate ARN provided is either:
- In a different region than the ALB
- Invalid or doesn't meet AWS requirements
- Not validated

**Solution**:

1. **Check certificate region**:
   ```bash
   aws acm describe-certificate --certificate-arn <arn> --region <region>
   ```
   The certificate must be in the **same region** as the ALB.

2. **Find valid certificate in the correct region**:
   ```bash
   aws acm list-certificates --region us-west-2
   ```

3. **Update terraform.tfvars**:
   ```hcl
   acm_certificate_arn = "arn:aws:acm:us-west-2:ACCOUNT_ID:certificate/CERT_ID"
   ```

4. **Or let Terraform create a new certificate**:
   - Set `acm_certificate_arn = ""` in terraform.tfvars
   - Terraform will create a new certificate
   - You'll need to validate it via DNS

## Auto Scaling Errors

### Error: "ECS service doesn't exist"

**Cause**: Auto scaling target is created before the ECS service exists.

**Solution**: Already fixed with `depends_on = [aws_ecs_service.main]` in autoscaling.tf

## Target Group Errors

### Error: "The target group does not have an associated load balancer"

**Cause**: The ALB listener failed to create (usually due to certificate issue), so the target group isn't properly associated.

**Solution**: Fix the certificate issue first, then the target group will work.

## Deployment Order

If you encounter dependency issues, deploy in this order:

1. **Network and Security** (foundation):
   ```bash
   terraform apply -target=module.network -target=module.security
   ```

2. **IAM and Monitoring**:
   ```bash
   terraform apply -target=module.iam -target=module.monitoring
   ```

3. **ECS Cluster**:
   ```bash
   terraform apply -target=module.ecs_cluster
   ```

4. **ALB** (fix certificate first):
   ```bash
   terraform apply -target=module.alb
   ```

5. **Task Definitions**:
   ```bash
   terraform apply -target=module.task_app -target=module.task_api2 ...
   ```

6. **Services**:
   ```bash
   terraform apply -target=module.service_app -target=module.service_api2 ...
   ```

## Certificate Validation

If Terraform creates a new certificate, you need to validate it:

1. **Get validation records**:
   ```bash
   terraform output acm_certificate_arn
   aws acm describe-certificate --certificate-arn <arn> --region <region>
   ```

2. **Add DNS records** to your domain

3. **Wait for validation** (can take a few minutes)

4. **Re-run terraform apply**

