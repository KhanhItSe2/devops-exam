terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0-beta1"
    }
  }
  backend "s3" {
    bucket  = "my-devops-exam"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}


#VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my-devops-exam-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-devops-exam-igw"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "my-devops-exam-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Route to Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "dev_sg" {
  name        = "dev-sg"
  description = "Allow SSH and all egress"
  vpc_id      = aws_vpc.main.id

  # Ingress for all required ports
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Consider restricting to your IP for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "dev-security-group"
  }
}

#EC2 Instance
resource "aws_instance" "go_coffeeshop_ec2" {
  ami                         = "ami-084568db4383264d4"
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.dev_sg.id]
  associate_public_ip_address = true

  # User data script for Docker installation
  user_data = <<-EOF
              #!/bin/bash
               # Install docker
              sudo apt-get update
              sudo apt-get install -y cloud-utils apt-transport-https ca-certificates curl software-properties-common
              sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              add-apt-repository \
                "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) \
                stable"
              sudo apt-get update
              sudo apt-get install -y docker-ce
              usermod -aG docker ubuntu

              # Install docker-compose
              curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose    

              # Create directory for Docker Compose
              sudo mkdir -p /home/ubuntu/dev-environment
              cd /home/ubuntu/dev-environment

              # Sample docker-compose.yml
              cat << 'DOCKER_COMPOSE' > docker-compose.yml

              services:
                app:
                  image: nginx:latest
                  ports:
                    - "80:80"
                  healthcheck:
                    test: ["CMD-SHELL", "curl -f http://localhost || exit 1"]
                    interval: 30s
                    timeout: 10s
                    retries: 5

                postgres:
                  image: postgres:14-alpine
                  container_name: postgres
                  environment:
                    POSTGRES_DB: coffeeshop
                    POSTGRES_USER: adminopswat
                    POSTGRES_PASSWORD: adminopswatpass
                  ports:
                    - "5432:5432"
                  volumes:
                    - postgres_data:/var/lib/postgresql/data

                rabbitmq:
                  image: rabbitmq:3.11-management-alpine
                  container_name: rabbitmq
                  environment:
                    RABBITMQ_DEFAULT_USER: guest
                    RABBITMQ_DEFAULT_PASS: guest
                  ports:
                    - "5672:5672"
                    - "15672:15672"

                product:
                  image: cuongopswat/go-coffeeshop-product
                  container_name: product
                  environment:
                    APP_NAME: product-service
                  ports:
                    - "5001:5001"
                  depends_on:
                    - postgres
                    - rabbitmq

                counter:
                  image: cuongopswat/go-coffeeshop-counter
                  container_name: counter
                  environment:
                    APP_NAME: counter-service
                    IN_DOCKER: "true"
                    PG_URL: postgres://adminopswat:adminopswatpass@postgres:5432/coffeeshop
                    PG_DSN_URL: host=postgres user=adminopswat password=adminopswatpass dbname=coffeeshop sslmode=disable
                    RABBITMQ_URL: amqp://guest:guest@rabbitmq:5672/
                    PRODUCT_CLIENT_URL: product:5001
                  ports:
                    - "5002:5002"
                  depends_on:
                    - postgres
                    - rabbitmq
                    - product

                proxy:
                  image: cuongopswat/go-coffeeshop-proxy
                  container_name: proxy
                  environment:
                    APP_NAME: proxy-service
                    GRPC_PRODUCT_HOST: product
                    GRPC_PRODUCT_PORT: 5001
                    GRPC_COUNTER_HOST: counter
                    GRPC_COUNTER_PORT: 5002
                  ports:
                    - "5000:5000"
                  depends_on:
                    - counter
                    - product

                web:
                  image: cuongopswat/go-coffeeshop-web
                  container_name: web
                  environment:
                    REVERSE_PROXY_URL: http://proxy:5000
                    WEB_PORT: 8888
                  ports:
                    - "8888:8888"
                  depends_on:
                    - proxy

                barista:
                  image: cuongopswat/go-coffeeshop-barista
                  container_name: barista
                  environment:
                    APP_NAME: barista-service
                    IN_DOCKER: "true"
                    PG_URL: postgres://adminopswat:adminopswatpass@postgres:5432/coffeeshop
                    PG_DSN_URL: host=postgres user=adminopswat password=adminopswatpass dbname=coffeeshop sslmode=disable
                    RABBITMQ_URL: amqp://guest:guest@rabbitmq:5672/
                  depends_on:
                    - postgres
                    - rabbitmq

                kitchen:
                  image: cuongopswat/go-coffeeshop-kitchen
                  container_name: kitchen
                  environment:
                    APP_NAME: kitchen-service
                    IN_DOCKER: "true"
                    PG_URL: postgres://adminopswat:adminopswatpass@postgres:5432/coffeeshop
                    PG_DSN_URL: host=postgres user=adminopswat password=adminopswatpass dbname=coffeeshop sslmode=disable
                    RABBITMQ_URL: amqp://guest:guest@rabbitmq:5672/
                  depends_on:
                    - postgres
                    - rabbitmq

              volumes:
                postgres_data:

              DOCKER_COMPOSE

              # Start Docker Compose
              sudo docker-compose up -d
EOF
  tags = {
    Name = "go-coffeeshop-vpc"
  }
}


