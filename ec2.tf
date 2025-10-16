# EC2 Instance for Web Application
resource "aws_instance" "web_app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.application.id]
  key_name               = var.key_name

  # Root volume configuration
  root_block_device {
    volume_size           = 25
    volume_type           = "gp2"
    delete_on_termination = true
  }

  # Disable termination protection
  disable_api_termination = false

  # User data script to configure application on first boot
  user_data = templatefile("${path.module}/user-data.sh", {
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  })

  tags = {
    Name = "${var.vpc_name}-web-app"
  }
}
