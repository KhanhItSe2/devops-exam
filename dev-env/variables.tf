variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  default = "us-east-1a"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "allowed_ip" {
  description = "Allowed IP address for SSH access"
  default     = "0.0.0.0/0"  
}

variable "key_name" {
  description = "DevOps exam key pair name"
  type        = string
}

