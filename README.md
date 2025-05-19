# DevOps Exam Project: Go-Coffeeshop Deployment

## Summary
This repository provides a Terraform-based solution to provision and deploy the infrastructure and application for the Go-Coffeeshop project. The solution includes setting up a Virtual Private Cloud (VPC), networking components, a security group, and an EC2 instance. The EC2 instance uses Docker and Docker Compose to run a multi-container application that consists of various microservices such as product, counter, proxy, web, barista, and kitchen services.

## Architecture
The architecture is designed to host a containerized application on AWS using the following components:
- **AWS VPC**: A logically isolated network in AWS.
- **Subnet**: A public subnet to host resources accessible via the internet.
- **Internet Gateway**: Enables internet access for resources inside the VPC.
- **Route Table**: Routes traffic to the internet gateway.
- **Security Group**: Controls inbound and outbound traffic to the EC2 instance.
- **EC2 Instance**: Hosts the application infrastructure using Docker and Docker Compose.

## Component Description
1. **Terraform Backend**:
   - Stores the Terraform state file in an S3 bucket for remote state management.
   
2. **VPC**:
   - A private network with DNS support and hostname resolution enabled.

3. **Subnet**:
   - A public subnet to host the EC2 instance.

4. **Internet Gateway**:
   - Provides internet connectivity for the resources inside the VPC.

5. **Route Table**:
   - Configures routes to send traffic to the internet gateway.

6. **Security Group**:
   - Allows inbound SSH access and unrestricted outbound traffic.

7. **EC2 Instance**:
   - Runs the Go-Coffeeshop application using Docker and Docker Compose.

8. **Docker Compose Services**:
   - **App**: Runs an NGINX web server.
   - **Postgres**: Database service for backend applications.
   - **RabbitMQ**: Message broker for inter-service communication.
   - **Microservices**:
     - Product, Counter, Proxy, Web, Barista, and Kitchen services.

## Homepage of the Application
- I can not deploy on Prod environment

## User Guideline
### Prerequisites
1. Install [Terraform](https://developer.hashicorp.com/terraform/downloads).
2. Have an AWS account with necessary IAM permissions.
3. Create an SSH key pair in AWS and note down the key name for use in `var.key_name`.

### Steps to Provision the Infrastructure and Deploy the Application
1. Clone this repository.
   ```bash
   git clone git@github.com:KhanhItSe2/devops-exam.git
   cd /dev-env
   ```

2. Initialize Terraform.
   ```bash
   terraform init
   ```

3. Define necessary variables in a `terraform.tfvars` file or pass them during runtime:
   ```hcl
   vpc_cidr = "10.0.0.0/16"
   public_subnet_cidr = "10.0.1.0/24"
   availability_zone = "us-east-1a"
   instance_type = "t2.micro"
   key_name = "devops-exam.pem"
   ```

4. Validate and apply the Terraform configuration.
   ```bash
   terraform validate
   terraform apply
   ```

5. Once the EC2 instance is created, retrieve the public IP from the Terraform output or AWS EC2 console.

6. Access the application:
   - Web Interface: `http://<EC2-Public-IP>:8888`
   - RabbitMQ Management: `http://<EC2-Public-IP>:15672` (default username: `guest`, password: `guest`)

### Notes
- To SSH into the EC2 instance:
   ```bash
   ssh -i <path-to-your-private-key> ubuntu@<EC2-Public-IP>
   ```

- Docker Compose is configured to automatically start all services on the EC2 instance.
- Make sure to terminate the EC2 instance and delete the associated resources when done to avoid unnecessary costs:
   ```bash
   terraform destroy
   ```

## Additional Information
- Terraform Provider: [HashiCorp AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- AMI ID: `ami-084568db4383264d4` (Ubuntu)
- Services:
  - **App**: NGINX
  - **Database**: PostgreSQL
  - **Message Broker**: RabbitMQ
  - **Go-Coffeeshop Microservices**: Product, Counter, Proxy, Web, Barista, Kitchen