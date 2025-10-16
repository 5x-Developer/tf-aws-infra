variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "vpc_name" {
  description = "Name tag for VPC"
  type        = string
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 3
  validation {
    condition     = var.public_subnet_count >= 1 && var.public_subnet_count <= 6
    error_message = "Public subnet count must be between 1 and 6."
  }
}

variable "private_subnet_count" {
  description = "Number of private subnets to create"
  type        = number
  default     = 3
  validation {
    condition     = var.private_subnet_count >= 1 && var.private_subnet_count <= 6
    error_message = "Private subnet count must be between 1 and 6."
  }
}

variable "public_subnet_cidr_bits" {
  description = "Number of bits to extend VPC CIDR for public subnets (e.g., 8 for /24 subnets in /16 VPC)"
  type        = number
  default     = 8
}

variable "private_subnet_cidr_bits" {
  description = "Number of bits to extend VPC CIDR for private subnets (e.g., 8 for /24 subnets in /16 VPC)"
  type        = number
  default     = 8
}

variable "private_subnet_offset" {
  description = "Offset for private subnet CIDR calculation to avoid overlap with public subnets"
  type        = number
  default     = 10
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name (optional)"
  type        = string
  default     = null
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "csye6225"
}

variable "db_user" {
  description = "Database user"
  type        = string
  default     = "csye6225user"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}