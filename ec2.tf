# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn2-ami-hvm-*-x86_64-gp2"]
#   }

#   filter {
#     name   = "architecture"
#     values = ["x86_64"]
#   }
# }
# data.aws_ami.amazon_linux.id
#ar.ami_id 

# EC2 Instance for Web Application
# resource "aws_instance" "web_app" {
#   ami                    = var.ami_id
#   instance_type          = var.instance_type
#   subnet_id              = aws_subnet.public[0].id
#   vpc_security_group_ids = [aws_security_group.application.id]
#   key_name               = var.key_name
#   iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name


#   # Root volume configuration
#   root_block_device {
#     volume_size           = 25
#     volume_type           = "gp2"
#     delete_on_termination = true
#   }

#   # Disable termination protection
#   disable_api_termination = false

#   # User data script to configure application on first boot
#   user_data = templatefile("${path.module}/user-data.sh", {
#     db_endpoint    = aws_db_instance.MySQL_DB.address
#     db_name        = var.db_name
#     db_user        = var.db_user
#     db_password    = var.db_password
#     s3_bucket_name = aws_s3_bucket.bucket.bucket
#     aws_region     = var.aws_region
#     log_group_name = "/aws/ec2/${var.vpc_name}-logs"
#   })

#   tags = {
#     Name = "${var.vpc_name}-web-app"
#   }
# }
