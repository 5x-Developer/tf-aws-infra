output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = aws_subnet.private[*].cidr_block
}

output "availability_zones" {
  description = "Availability zones used"
  value       = distinct(concat(aws_subnet.public[*].availability_zone, aws_subnet.private[*].availability_zone))
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private.id
}

# Helpful output for Packer
output "default_subnet_id" {
  description = "First public subnet ID (useful for Packer builds)"
  value       = aws_subnet.public[0].id
}

# EC2 Instance outputs
# output "instance_id" {
#   description = "ID of the EC2 instance"
#   value       = aws_instance.web_app.id
# }

# output "instance_public_ip" {
#   description = "Public IP of the EC2 instance"
#   value       = aws_instance.web_app.public_ip
# }

# output "application_url" {
#   description = "URL to access the application"
#   value       = "http://${aws_instance.web_app.public_ip}:8080"
# }

# output "security_group_id" {
#   description = "ID of the application security group"
#   value       = aws_security_group.application.id
# }

# output "ec2_public_ip" {
#   description = "Public IP address of the EC2 instance"
#   value       = aws_instance.web_app.public_ip
# }

# Output the domain name
output "application_domain" {
  description = "Domain name for accessing the application"
  value       = aws_route53_record.app.name
}


# Output the Route 53 zone ID (useful for debugging)
output "route53_zone_id" {
  description = "Route 53 hosted zone ID"
  value       = data.aws_route53_zone.main.zone_id
}

# Load Balancer outputs
# output "load_balancer_dns" {
#   description = "DNS name of the load balancer"
#   value       = aws_lb.application_load_balancer.dns_name
# }

# output "load_balancer_arn" {
#   description = "ARN of the load balancer"
#   value       = aws_lb.application_load_balancer.arn
# }

# output "target_group_arn" {
#   description = "ARN of the target group"
#   value       = aws_lb_target_group.lb_tg.arn
# }

output "autoscaling_group_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${var.domain_name}"
}