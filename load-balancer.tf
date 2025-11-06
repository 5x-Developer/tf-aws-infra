resource "aws_lb_target_group" "lb_tg" {
  name        = "${var.vpc_name}-lb-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = "/api/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
  deregistration_delay = 60

  tags = {
    Name = "${var.vpc_name}-lb-tg"
  }
}


resource "aws_lb" "application_load_balancer" {
  name               = "${var.vpc_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = aws_subnet.public[*].id
  tags = {
    Name = "${var.vpc_name}-lb"
  }
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }

  tags = {
    Name = "${var.vpc_name}-lb-listener"
  }
}