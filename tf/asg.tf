resource "aws_launch_template" "app" {
  name_prefix            = "${var.environment}-app-"
  image_id               = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  ebs_optimized          = false
  key_name               = aws_key_pair.default.key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  user_data              = base64encode(data.template_file.main.rendered)

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }

  block_device_mappings {
    device_name = data.aws_ami.ubuntu.root_device_name

    ebs {
      volume_type           = "gp2"
      volume_size           = 10
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "app" {
  name_prefix               = "${var.environment}-app-"
  min_size                  = 2
  desired_capacity          = 2
  max_size                  = 2
  health_check_grace_period = 120
  health_check_type         = var.asg_health_check_type
  default_cooldown          = 900
  vpc_zone_identifier       = module.vpc.private_subnets
  force_delete              = "false"
  termination_policies      = ["OldestLaunchTemplate"]
  wait_for_capacity_timeout = 0

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [target_group_arns]
  }

  enabled_metrics = [
    "GroupStandbyInstances",
    "GroupTotalInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMinSize",
    "GroupMaxSize",
  ]

  tag {
    key                 = "Name"
    value               = "${var.environment}-app"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "app" {
  autoscaling_group_name = aws_autoscaling_group.app.id
  alb_target_group_arn   = aws_alb_target_group.app.arn
}
