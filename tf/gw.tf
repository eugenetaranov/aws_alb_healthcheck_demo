resource "aws_security_group" "gw" {
  name_prefix = "${var.environment}-gw-"
  description = var.environment
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "gw_ssh_ingress" {
  description       = "${var.environment} gw ssh in"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gw.id
}

resource "aws_security_group_rule" "gw_egress" {
  description       = "${var.environment} egress"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.gw.id
}

resource "aws_security_group_rule" "app_ssh_ingress" {
  description              = "${var.environment} app ssh in"
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gw.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_instance" "gw" {
  instance_type               = "t3.micro"
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.gw.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.default.key_name

  root_block_device {
    volume_type           = "standard"
    volume_size           = 10
    delete_on_termination = true
  }

  tags = merge(
    {
      "Name" = "${var.environment}-gw",
    },
    var.tags,
  )
}

output "gw_id" {
  value = aws_instance.gw.id
}

output "gw_ip" {
  value = aws_instance.gw.public_ip
}
