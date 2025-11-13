# DB Parameter Group 
resource "aws_db_parameter_group" "db_parameter" {
  name        = "${var.vpc_name}-db-parameter-group"
  family      = "mysql8.0"
  description = "Custom parameter group"

  parameter {

    name  = "character_set_server"
    value = "utf8mb4"

  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  tags = {
    Name = "${var.vpc_name}-db-parameter-group"
  }
}

# DB Subnet Group 
resource "aws_db_subnet_group" "pvt_subnet_for_db" {
  name        = "${var.vpc_name}-db-subnet-group"
  subnet_ids  = aws_subnet.private[*].id
  description = "Private subnets for RDS instances"

  tags = {
    Name = "${var.vpc_name}-db-subnet-group"
  }
}

# RDS Instance 
resource "aws_db_instance" "MySQL_DB" {
  identifier             = "csye6225"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t4g.micro"
  db_name                = var.db_name
  username               = var.db_user
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.db_parameter.name
  db_subnet_group_name   = aws_db_subnet_group.pvt_subnet_for_db.name
  vpc_security_group_ids = [aws_security_group.database.id]
  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true

  # KMS encryption for RDS
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_key.arn

  tags = {
    Name = "${var.vpc_name}-rds-instance"
  }
}

# Output 
output "rds_endpoint" {
  value       = aws_db_instance.MySQL_DB.address
  description = "RDS instance endpoint"
}

output "rds_port" {
  value       = aws_db_instance.MySQL_DB.port
  description = "RDS instance port"
}