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


data "aws_route53_zone" "main" {
  name         = "${var.domain_name}."
  private_zone = false
}

# A Record - Alias to Load Balancer
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.application_load_balancer.dns_name
    zone_id                = aws_lb.application_load_balancer.zone_id
    evaluate_target_health = true
  }
}