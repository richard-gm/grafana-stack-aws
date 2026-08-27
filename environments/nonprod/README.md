# Nonprod Environment

## Overview

This environment deploys the Grafana Stack for non-production use (development, testing, staging).

## Architecture

```mermaid
flowchart TD
    subgraph Modules["Terraform Modules"]
        VPC_MOD[VPC Module]
        SEC_MOD[Security Module]
        ECS_MOD[ECS Module]
        ECR_MOD[ECR Containers Module]
    end

    subgraph Resources["AWS Resources"]
        VPC_RES[VPC\n10.0.0.0/16]
        SUBNETS[Public/Private Subnets]
        SG[Security Groups]
        ECS_CLUSTER[ECS Cluster]
        SERVICES[Grafana/Prometheus/Pushgateway]
        ECR_REPOS[ECR Repositories]
    end

    VPC_MOD --> VPC_RES
    VPC_MOD --> SUBNETS
    SEC_MOD --> SG
    ECS_MOD --> ECS_CLUSTER
    ECS_MOD --> SERVICES
    ECR_MOD --> ECR_REPOS

    VPC_RES --> ECS_CLUSTER
    SUBNETS --> SERVICES
    SG --> SERVICES
```

## Files

| File | Description |
|------|-------------|
| `main.tf` | Provider config and module calls |
| `variables.tf` | Variable declarations |
| `terraform.tfvars` | Environment-specific values |
| `backend.tf` | S3 backend configuration |

## Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "grafana-stack-terraform-state"
    key            = "nonprod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    versioning     = true
  }
}
```

## Environment Values

| Variable | Value |
|----------|-------|
| `project_name` | grafana-stack |
| `env_subfix` | nonprod |
| `region` | us-east-1 |
| `tags_project.Environment` | nonprod |

## Deployment

```bash
cd environments/nonprod

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply
```

## Module Dependencies

```mermaid
flowchart LR
    VPC[VPC Module] --> SEC[Security Module]
    SEC --> ECS[ECS Module]
    ECR[ECR Containers Module] -.-> ECS
```

1. **VPC Module** - Creates networking infrastructure
2. **Security Module** - Creates security groups (depends on VPC)
3. **ECS Module** - Creates ECS services (depends on VPC, Security)
4. **ECR Containers Module** - Creates ECR repos (independent)
