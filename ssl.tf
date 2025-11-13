# SSL Certificate Configuration
# This creates/uses SSL certificate for your domain

# Note: Using the existing Route 53 data source from your route53.tf
# (data.aws_route53_zone.main)

# Request ACM certificate with DNS validation
# resource "aws_acm_certificate" "app_cert" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }

#   tags = {
#     Name = "${var.vpc_name}-ssl-certificate"
#   }
# }

# # DNS validation record
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.app_cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.main.zone_id
# }

# # Wait for certificate validation
# resource "aws_acm_certificate_validation" "cert_validation" {
#   certificate_arn         = aws_acm_certificate.app_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

#   timeouts {
#     create = "10m"
#   }
# }

# # Output certificate ARN
# output "certificate_arn" {
#   value       = aws_acm_certificate.app_cert.arn
#   description = "ARN of the SSL certificate"
# }

# output "certificate_status" {
#   value       = aws_acm_certificate.app_cert.status
#   description = "Status of the SSL certificate"
# }

# IMPORTANT FOR DEMO ENVIRONMENT:
# If you need to import a certificate purchased from Namecheap (for demo account):
# 1. Comment out the resources above (aws_acm_certificate, aws_route53_record, aws_acm_certificate_validation)
# 2. Import the certificate using AWS CLI (see SSL_CERTIFICATE_IMPORT.md)
# 3. Use a data source to reference the imported certificate:
#
# data "aws_acm_certificate" "imported_cert" {
#   domain   = var.domain_name
#   statuses = ["ISSUED"]
# }
#
# Then in load-balancer.tf, use: data.aws_acm_certificate.imported_cert.arn