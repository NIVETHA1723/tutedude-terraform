# Terraform AWS Deployment Project

This project demonstrates three different ways to deploy a Flask backend and an Express frontend on AWS using Terraform.

## Architecture

### Part 1: Single EC2 Deployment
- A single EC2 instance (t3.micro, Ubuntu) running both apps.
- Apps installed and managed via `user_data` script.
- Flask runs on port 5000, Express on port 3000.

### Part 2: Two EC2 Instances
- Separate EC2 instances for Frontend and Backend.
- Security groups configured to allow communication between instances.
- Frontend calls Backend via private IP.

### Part 3: Docker + ECR + ECS + ALB
- Infrastructure: VPC with public subnets.
- Containerization: Dockerfiles for both apps.
- Storage: ECR repositories for images.
- Orchestration: ECS Fargate cluster and services.
- Routing: Application Load Balancer (ALB) with path-based routing:
  - `/api` -> Flask Service
  - `/` -> Express Service

## Setup & Deployment

### Prerequisites
- AWS CLI configured with credentials.
- Terraform installed (>= 1.0.0).
- Docker installed (for Part 3).

### Step 1: Initialize Terraform
```bash
terraform init
```

### Step 2: Deploy Infrastructure
```bash
terraform apply -auto-approve
```

### Step 3: Build & Push Docker Images (For Part 3)
Note: Replace `<ACCOUNT_ID>` and `<REGION>` with your actual values.

1. **Login to ECR:**
```bash
aws ecr get-login-password --region <REGION> | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com
```

2. **Build and Push Flask App:**
```bash
cd apps/flask-app
docker build -t flask-app .
docker tag flask-app:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/flask-app:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/flask-app:latest
```

3. **Build and Push Express App:**
```bash
cd ../express-app
docker build -t express-app .
docker tag express-app:latest <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/express-app:latest
docker push <ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/express-app:latest
```

### Step 4: Access the Applications
Check the Terraform outputs for the URLs:
- **Part 1:** `part1_flask_url`, `part1_express_url`
- **Part 2:** `part2_backend_url`, `part2_frontend_url`
- **Part 3:** `part3_alb_dns`

## Project Structure
- `apps/`: Application source code and Dockerfiles.
- `modules/`: Reusable Terraform modules (VPC, EC2, ECS, ALB, ECR).
- `part1/`, `part2/`, `part3/`: Configuration for each part.
- `main.tf`, `variables.tf`, `outputs.tf`, `provider.tf`: Root Terraform files.
