# Target Group
resource "aws_lb_target_group" "lb_tg" {
  name        = "${var.vpc_name}-lb-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/api/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 60

  tags = {
    Name = "${var.vpc_name}-lb-tg"
  }
}

# Application Load Balancer
resource "aws_lb" "application_load_balancer" {
  name               = "${var.vpc_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false
  enable_http2               = true

  tags = {
    Name = "${var.vpc_name}-lb"
  }
}

# HTTP Listener - Return 403 (not supporting plain HTTP)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "HTTPS Required - Please use https://${var.domain_name}"
      status_code  = "403"
    }
  }

  tags = {
    Name = "${var.vpc_name}-http-listener"
  }
}

# HTTPS Listener (Port 443)
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.app_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }

  tags = {
    Name = "${var.vpc_name}-https-listener"
  }
}

# SSL Certificate Configuration
# Get the Route53 hosted zone
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

# CHANGED: Use data source to reference imported Namecheap certificate
data "aws_acm_certificate" "app_cert" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

# COMMENTED OUT: No longer creating certificate via ACM
# These resources are replaced by the imported Namecheap certificate above

# resource "aws_acm_certificate" "app_cert" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"
#
#   lifecycle {
#     create_before_destroy = true
#   }
#
#   tags = {
#     Name = "${var.vpc_name}-ssl-certificate"
#   }
# }

# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.app_cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.selected.zone_id
# }

# resource "aws_acm_certificate_validation" "cert_validation" {
#   certificate_arn         = aws_acm_certificate.app_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
#
#   timeouts {
#     create = "10m"
#   }
# }

# Outputs
output "load_balancer_dns" {
  value       = aws_lb.application_load_balancer.dns_name
  description = "DNS name of the load balancer"
}

output "load_balancer_arn" {
  value       = aws_lb.application_load_balancer.arn
  description = "ARN of the load balancer"
}

output "load_balancer_zone_id" {
  value       = aws_lb.application_load_balancer.zone_id
  description = "Zone ID of the load balancer"
}

output "certificate_arn" {
  value       = data.aws_acm_certificate.app_cert.arn
  description = "ARN of the SSL certificate (imported from Namecheap)"
}

# NOTE: Certificate was imported using the following command:
# aws acm import-certificate \
#   --certificate fileb://aditya-y_me.crt \
#   --private-key fileb://private.key \
#   --certificate-chain fileb://ca_bundle.ca-bundle \
#   --region us-east-1 \
#   --profile demo