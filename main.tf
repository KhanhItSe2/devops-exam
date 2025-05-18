terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "6.0.0-beta1"
    }
  }
  backend "s3" {
    bucket         = "my-devops-exam"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}


#VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
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
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "my-devops-exam-public-subnet"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

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

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 15672
    to_port     = 15672
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  tags = {
    Name = "dev-security-group"
  }
}

#EC2 Instance
resource "aws_instance" "go_coffeeshop_ec2" {
  ami           = "ami-084568db4383264d4" 
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.dev_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "go-coffeeshop-vpc"
  }
}