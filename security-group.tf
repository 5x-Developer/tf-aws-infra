# Application Security Group
resource "aws_security_group" "application" {
  name        = "${var.vpc_name}-application-sg"
  description = "Security group for web application instances"
  vpc_id      = aws_vpc.main.id

  # SSH - Port 22
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application Port - 8080 (Spring Boot) from lb
  ingress {
    description     = "Application port from load balancer only"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-application-sg"
  }
}

# Database Security Group
resource "aws_security_group" "database" {
  name        = "${var.vpc_name}-database-sg"
  description = "Security group for DB instances"
  vpc_id      = aws_vpc.main.id

  # MySQL port
  ingress {
    description     = "MySQL from application"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  # Outbound rules
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vpc_name}-database-sg"
  }
}

# Load Balancer Security Group
resource "aws_security_group" "load_balancer" {
  name        = "${var.vpc_name}-lb-sg"
  description = "Security group for load balancers"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-lb-sg"
  }
}

# Load Balancer Ingress - HTTP IPv4
resource "aws_vpc_security_group_ingress_rule" "lb_http_ipv4" {
  security_group_id = aws_security_group.load_balancer.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTP from internet (IPv4)"
}

# Load Balancer Ingress - HTTP IPv6
resource "aws_vpc_security_group_ingress_rule" "lb_http_ipv6" {
  security_group_id = aws_security_group.load_balancer.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv6         = "::/0"
  description       = "Allow HTTP from internet (IPv6)"
}

# Load Balancer Ingress - HTTPS IPv4
resource "aws_vpc_security_group_ingress_rule" "lb_https_ipv4" {
  security_group_id = aws_security_group.load_balancer.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTPS from internet (IPv4)"
}

# Load Balancer Ingress - HTTPS IPv6
resource "aws_vpc_security_group_ingress_rule" "lb_https_ipv6" {
  security_group_id = aws_security_group.load_balancer.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv6         = "::/0"
  description       = "Allow HTTPS from internet (IPv6)"
}

# Load Balancer Egress - To Application Instances
resource "aws_vpc_security_group_egress_rule" "lb_to_app" {
  security_group_id            = aws_security_group.load_balancer.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.application.id
  description                  = "Forward traffic to application instances"
}