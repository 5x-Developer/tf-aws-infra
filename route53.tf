# data "aws_route53_zone" "main" {
#   name         = "${var.domain_name}."
#   private_zone = false
# }

# resource "aws_route53_record" "app" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "A"
#   ttl     = var.dns_ttl
#   records = [aws_instance.web_app.public_ip]
# }