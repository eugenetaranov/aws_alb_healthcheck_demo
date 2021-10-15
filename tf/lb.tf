provider "aws" {}

resource "aws_security_group" "lb" {
  name_prefix = "${var.environment}-lb-"
  description = var.environment
  vpc_id      = module.vpc.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "lb_http_ingress" {
  description = "${var.environment} http in"
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "lb_egress" {
  description = "${var.environment} http egress"
  type        = "egress"
  from_port   = var.app_port
  to_port     = var.app_port
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.lb.id
}

resource "aws_lb" "default" {
  name                             = var.environment
  internal                         = false
  security_groups                  = [aws_security_group.lb.id]
  enable_cross_zone_load_balancing = true
  subnets                          = module.vpc.public_subnets
  enable_deletion_protection       = false
  idle_timeout                     = 120

  tags = var.tags
}

resource "aws_alb_listener" "default_http" {
  load_balancer_arn = aws_lb.default.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "app" {
  name                 = "${var.environment}-app"
  port                 = var.app_port
  protocol             = "HTTP"
  vpc_id               = module.vpc.vpc_id
  deregistration_delay = 30
  proxy_protocol_v2    = false

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  health_check {
    healthy_threshold   = 2
    interval            = var.elb_healthcheck["interval"]
    matcher             = 200
    path                = "/"
    protocol            = "HTTP"
    timeout             = var.elb_healthcheck["timeout"]
    unhealthy_threshold = 2
  }

  tags = var.tags
}

resource "aws_lb_target_group_attachment" "app" {
  count            = var.app_nodes_num
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = var.app_port
}

output "app_url" {
  value = "http://${aws_lb.default.dns_name}"
}
