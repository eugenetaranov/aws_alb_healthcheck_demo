resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-"
  description = var.environment
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags
}

resource "aws_security_group_rule" "app_http_ingress" {
  description              = "${var.environment} http in"
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress" {
  description       = "${var.environment} http egress"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_key_pair" "default" {
  key_name_prefix = "${var.environment}-"
  public_key      = file("id_rsa.pub")
}

resource "aws_instance" "app" {
  count                       = var.app_nodes_num
  instance_type               = "t3.micro"
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = false
  user_data                   = data.template_file.main.rendered
  key_name                    = aws_key_pair.default.key_name
  iam_instance_profile        = aws_iam_instance_profile.app.name

  root_block_device {
    volume_type           = "standard"
    volume_size           = 10
    delete_on_termination = true
  }

  tags = merge(
    {
      "Name" = "${var.environment}-app-${count.index}",
    },
    var.tags,
  )
}

resource "aws_iam_instance_profile" "app" {
  name_prefix = "${var.environment}-"
  role        = aws_iam_role.app.id
}

resource "aws_iam_role" "app" {
  name_prefix        = "${var.environment}-"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy_app.json
}

data "aws_iam_policy_document" "assume_role_policy_app" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "test_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

locals {
  src_app = {
    "../apps/server/src/app.py"                    = "/opt/app/app.py"
    "../apps/server/src/requirements.txt"          = "/opt/app/requirements.txt",
    "../apps/server/src/elb_healthcheck_delay.txt" = "/opt/app/elb_healthcheck_delay.txt",
    "../apps/server/src/default_delay.txt"         = "/opt/app/default_delay.txt",
  }
}

data "template_file" "main" {
  template = <<EOF
#cloud-config
package_update: true
timezone: UTC
packages:
  - python3.8-venv
write_files:
%{~for src_path, dest_path in local.src_app}
  - content: |
      ${indent(6, file(src_path))}
    path: ${dest_path}
    permissions: 0644
    owner: root:root
%{endfor~}
  - content: |
      [Unit]
      Description=App
      Wants=network-online.target
      After=network-online.target

      [Service]
      User=app
      WorkingDirectory=/opt/app
      ExecStart=/opt/app/venv/bin/python /opt/app/app.py
      Restart=always

      [Install]
      WantedBy=multi-user.target
    path: /etc/systemd/system/app.service
    permissions: 0644
    owner: root:root
runcmd:
  - snap install amazon-ssm-agent --classic
  - systemctl start snap.amazon-ssm-agent.amazon-ssm-agent.service
  - systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent.service
  - python3 -m venv /opt/app/venv
  - /opt/app/venv/bin/pip install -r /opt/app/requirements.txt
  - systemctl daemon-reload
  - systemctl enable app.service
  - systemctl restart app.service
users:
  - name: app
    shell: /bin/false
    system: true
    home: /opt/app
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${file("id_rsa.pub")}
EOF
}

output "app_id" {
  value = aws_instance.app.*.id
}

output "app_private_ip" {
  value = aws_instance.app.*.private_ip
}

output "ssh_connection" {
  value = {
    for i, instance in aws_instance.app :
    i => "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -J ubuntu@${aws_instance.gw.public_ip} ubuntu@${instance.private_ip}"
  }
}
