# Launch Template for Auto Scaling Group
resource "aws_launch_template" "app" {
  name          = "${var.vpc_name}-launch-template"
  description   = "Launch template for web application instances"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application.id]
    delete_on_termination       = true
  }

  # Added KMS encryption for EBS volumes
  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 25
      volume_type           = "gp2"
      delete_on_termination = true
      # encrypted             = true
      # kms_key_id            = aws_kms_key.ec2_key.arn
    }
  }

  #   user_data template variables
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_secret_arn  = aws_secretsmanager_secret.rds_credentials.arn
    s3_bucket_name = aws_s3_bucket.bucket.bucket
    aws_region     = var.aws_region
    log_group_name = "/aws/ec2/${var.vpc_name}-logs"
    sns_topic_arn  = aws_sns_topic.user_verification.arn
    domain_name    = var.domain_name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.vpc_name}-web-app"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.vpc_name}-web-app-volume"
    }
  }

  tags = {
    Name = "${var.vpc_name}-launch-template"
  }
}


# Auto Scaling Group
resource "aws_autoscaling_group" "app" {
  name                      = "${var.vpc_name}-asg"
  desired_capacity          = 3
  max_size                  = 5
  min_size                  = 3
  default_cooldown          = 60
  health_check_type         = "ELB"
  health_check_grace_period = 300

  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.lb_tg.arn]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.vpc_name}-asg-instance"
    propagate_at_launch = true
  }

  # Instance refresh configuration for CI/CD deployments
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }
}

# Scale Up Policy - Add 1 instance
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.vpc_name}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
}

# Scale Down Policy - Remove 1 instance
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.vpc_name}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.app.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
}

# CloudWatch Alarm - High CPU (triggers scale up)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.vpc_name}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 65
  alarm_description   = "This metric monitors high CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

# CloudWatch Alarm - Low CPU (triggers scale down)
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.vpc_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 6
  alarm_description   = "This metric monitors low CPU utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}