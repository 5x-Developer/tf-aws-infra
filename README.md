# AWS Infrastructure — Terraform

Terraform configuration for provisioning the complete AWS infrastructure behind the [Cloud-Native Web Application](https://github.com/5x-Developer/Web_app). Manages networking, compute, database, storage, serverless, security, observability, and DNS across **dev** and **demo** environments (79 resources per environment). 

Built as part of **CSYE 6225 — Network Structures & Cloud Computing** at Northeastern University.

---

## Architecture

```
                         Internet
                            │
                      ┌─────┴─────┐
                      │  Route 53  │──── demo.aditya-y.me
                      └─────┬─────┘
                            │ (A record alias)
                      ┌─────┴─────┐
                      │    ALB    │──── HTTPS (443) + SSL/TLS 1.3
                      │  (public) │     HTTP (80) → 403
                      └─────┬─────┘
                            │
               ┌────────────┼────────────┐
               │            │            │
          ┌────┴────┐  ┌────┴────┐  ┌────┴────┐
          │   EC2   │  │   EC2   │  │   EC2   │   Auto Scaling Group
          │  (AZ-a) │  │  (AZ-b) │  │  (AZ-c) │   (min 3, max 5)
          └────┬────┘  └────┬────┘  └────┬────┘
               │            │            │         Public Subnets
        ───────┼────────────┼────────────┼─────────────────────
               │            │            │         Private Subnets
               └────────────┼────────────┘
                            │
                      ┌─────┴─────┐
                      │  RDS MySQL │──── KMS encrypted
                      │  (private) │
                      └───────────┘

    SNS Topic ──→ Lambda ──→ SendGrid (email verification)
                    │
                    ├── Secrets Manager (SendGrid API key)
                    └── DynamoDB (idempotency tracking)

    S3 Bucket ──── Product images (KMS encrypted, lifecycle → IA after 30d)
```

---

## Resources Provisioned

### Networking (`vpc.tf`, `route53.tf`)
- VPC with configurable CIDR and DNS support
- 3 public subnets + 3 private subnets across AZs (dynamic CIDR via `cidrsubnet()`)
- Internet Gateway + public/private route tables
- Route 53 A record (alias to ALB)

### Compute (`autoscaling.tf`, `ec2.tf`)
- Launch Template with custom AMI, instance profile, and user-data bootstrap
- Auto Scaling Group (3–5 instances, rolling refresh with 50% min healthy)
- CloudWatch alarms for CPU-based scaling (scale up at 65%, down at 6%)

### Load Balancing & SSL (`load-balancer.tf`, `ssl.tf`)
- Application Load Balancer (public, HTTP/2 enabled)
- HTTPS listener (TLS 1.3 policy) with imported Namecheap SSL certificate
- HTTP listener returns 403 (HTTPS enforced)
- Target group with `/api/health` health checks

### Database (`rds.tf`)
- RDS MySQL 8.0 (`db.t4g.micro`) in private subnets
- KMS-encrypted storage, custom parameter group (utf8mb4)
- Credentials stored in Secrets Manager, fetched by EC2 at boot

### Storage (`S3.tf`)
- S3 bucket with randomized name, KMS encryption, versioning
- Lifecycle policy (transition to Standard-IA after 30 days)
- All public access blocked

### Serverless (`lambda.tf`, `sns.tf`, `dynamo_db.tf`)
- SNS topic for user verification events
- Lambda function (Java 17, 512MB) subscribed to SNS
- DynamoDB table for email delivery tracking (TTL-enabled, KMS-encrypted, PITR)
- Secrets Manager secret for SendGrid credentials

### Security (`security-group.tf`, `iam.tf`, `kms.tf`)
- **Load Balancer SG** — inbound 80/443 from internet, outbound 8080 to app only
- **Application SG** — inbound 8080 from LB only, SSH (22) open
- **Database SG** — inbound 3306 from application SG only
- **EC2 IAM role** — least-privilege policies for S3, CloudWatch, SNS, Secrets Manager, KMS
- **Lambda IAM role** — policies for DynamoDB, Secrets Manager, CloudWatch Logs, KMS
- **4 KMS keys** with 90-day rotation — EC2/EBS, RDS, S3, Secrets Manager

### Secrets (`secrets.tf`)
- RDS credentials (host, port, dbname, username, password) — KMS-encrypted
- Email service credentials (SendGrid API key, from address) — KMS-encrypted

---

## Prerequisites

- **Terraform** >= 1.0
- **AWS CLI** configured with `dev` and `demo` profiles
- **Custom AMI** built via Packer (from the [Web App repo](https://github.com/5x-Developer/Web_app))
- **SSL certificate** imported into ACM (Namecheap cert for demo)
- **Route 53 hosted zone** for your domain

---

## Usage

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Create a `terraform.tfvars` file

Use one of the example files as a starting point:

```bash
cp demo.tfvars.example terraform.tfvars
```

Then fill in the required values:

```hcl
aws_region         = "us-east-1"
aws_profile        = "demo"
vpc_cidr           = "10.1.0.0/16"
vpc_name           = "demo-vpc"
domain_name        = "demo.aditya-y.me"
ami_id             = "ami-xxxxxxxxx"       # From Packer build
db_password        = "your-db-password"
email_api_key      = "SG.xxxxx"            # SendGrid API key
email_from_address = "noreply@demo.aditya-y.me"
```

### 3. Create the Lambda placeholder (first-time only)

```bash
bash create-lambda-placeholder.sh
```

This creates a `lambda_function.zip` so Terraform can provision the Lambda resource. The real code is deployed later via the [serverless repo's](https://github.com/your-org/serverless) CI/CD pipeline.

### 4. Plan and apply

```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

---

## Environments

The infrastructure supports multiple environments via separate `.tfvars` files and AWS profiles:

| Environment | Profile | VPC CIDR | Domain |
|---|---|---|---|
| **dev** | `dev` | `10.0.0.0/16` | `dev.aditya-y.me` |
| **demo** | `demo` | `10.1.0.0/16` | `demo.aditya-y.me` |

---

## Variables Reference

| Variable | Description | Default |
|---|---|---|
| `aws_region` | AWS region | — |
| `aws_profile` | AWS CLI profile | — |
| `vpc_cidr` | VPC CIDR block | — |
| `vpc_name` | Name prefix for all resources | — |
| `domain_name` | Application domain | — |
| `ami_id` | Custom AMI from Packer | — |
| `instance_type` | EC2 instance type | `t2.micro` |
| `db_name` | RDS database name | `csye6225` |
| `db_user` | RDS username | `csye6225` |
| `db_password` | RDS password (sensitive) | — |
| `email_api_key` | SendGrid API key (sensitive) | — |
| `email_from_address` | Sender email address | — |
| `public_subnet_count` | Number of public subnets | `3` |
| `private_subnet_count` | Number of private subnets | `3` |
| `lambda_zip_path` | Path to Lambda deployment package | `lambda_function.zip` |

---

## Project Structure

```
├── vpc.tf                 # VPC, subnets, route tables, IGW
├── security-group.tf      # LB, application, and database security groups
├── load-balancer.tf       # ALB, target group, HTTP/HTTPS listeners
├── ssl.tf                 # SSL certificate configuration (ACM/Namecheap)
├── route53.tf             # DNS A record (alias to ALB)
├── autoscaling.tf         # Launch template, ASG, scaling policies, CloudWatch alarms
├── ec2.tf                 # (Legacy single-instance config, commented out)
├── rds.tf                 # RDS MySQL instance, parameter group, subnet group
├── S3.tf                  # S3 bucket with encryption, lifecycle, versioning
├── iam.tf                 # EC2 IAM role + policies (S3, CloudWatch, SNS, Secrets Manager)
├── kms.tf                 # KMS keys for EC2, RDS, S3, Secrets Manager
├── secrets.tf             # Secrets Manager secrets (RDS creds, email creds)
├── lambda.tf              # Lambda function, IAM role + policies, CloudWatch log group
├── sns.tf                 # SNS topic, topic policy, Lambda subscription
├── dynamo_db.tf           # DynamoDB email tracking table
├── variables.tf           # Input variables with validation
├── outputs.tf             # Output values
├── provider.tf            # AWS provider configuration
├── user-data.sh           # EC2 bootstrap script (Secrets Manager fetch, CloudWatch Agent config)
├── create-lambda-placeholder.sh  # Creates initial Lambda zip for first terraform apply
├── dev.tfvars.example     # Example config for dev environment
└── demo.tfvars.example    # Example config for demo environment
```

---

## EC2 Bootstrap Flow (`user-data.sh`)

On first boot, each EC2 instance:

1. Fetches RDS credentials from **Secrets Manager** (no hardcoded passwords)
2. Writes a `.env` file to `/opt/csye6225/` with database URL, S3 bucket, SNS topic ARN, and app domain
3. Configures the **CloudWatch Agent** with application log collection, memory/disk metrics, and StatsD receiver (port 8125)
4. Starts the CloudWatch Agent and verifies it's running
5. Restarts the `csye6225` systemd service to pick up the configuration

---

## Related Repositories

- **[Web Application](https://github.com/your-org/Web_app)** — Spring Boot REST API (builds the custom AMI via Packer)
- **[Serverless](https://github.com/your-org/serverless)** — Lambda function for email verification (deployed via CI/CD)

---

## License

This project was built for academic purposes as part of CSYE 6225 at Northeastern University.
