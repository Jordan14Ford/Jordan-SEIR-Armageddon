# EC2 and ALB — São Paulo (sa-east-1)
# Role: stateless compute satellite — no RDS, no PHI storage
# All DB traffic goes over TGW to Tokyo RDS

# ---------------------------------------------------------------------------
# IAM — instance role for São Paulo EC2
# SSM and CloudWatch only. No Secrets Manager: this region has no DB
# credentials to fetch — the app connects to Tokyo RDS over TGW using
# endpoint from Terraform remote state; Tokyo holds the credentials.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "sao_paulo_ec2_role" {
  name = "${var.project}-sao-paulo-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project}-sao-paulo-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "sao_paulo_ssm_policy" {
  role       = aws_iam_role.sao_paulo_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "sao_paulo_cloudwatch_policy" {
  role       = aws_iam_role.sao_paulo_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "sao_paulo_ec2_profile" {
  name = "${var.project}-sao-paulo-ec2-profile"
  role = aws_iam_role.sao_paulo_ec2_role.name
}

# ---------------------------------------------------------------------------
# EC2 — São Paulo app instance
# Private subnet only — no public IP
# Access via SSM Session Manager, not SSH
# App managed by systemd (not nohup) — survives reboots and crashes
#
# Debugging tip: if the app doesn't start after launch, check:
#   /var/log/cloud-init-output.log  — bootstrap script output
#   journalctl -u flask             — systemd service logs
# ---------------------------------------------------------------------------

resource "aws_instance" "sao_paulo_app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.sao_paulo_private_1.id
  vpc_security_group_ids      = [aws_security_group.sao_paulo_ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.sao_paulo_ec2_profile.name
  associate_public_ip_address = false

  # user_data runs once on first boot via cloud-init
  # <<-EOF strips leading spaces from content lines
  # closing EOF must be flush-left at column zero — bash won't match it otherwise
  user_data = <<-EOF
    #!/bin/bash
    set -e
    yum update -y
    yum install -y python3 python3-pip

    pip3 install flask pymysql

    mkdir -p /opt/app

    # Python content must be flush-left inside this heredoc
    # <<-EOF strips the outer indentation but APPEOF content
    # is written to disk exactly as it appears here
    # indented Python = IndentationError on startup
    cat > /opt/app/app.py << 'APPEOF'
from flask import Flask, jsonify
import os
import socket

app = Flask(__name__)

# Tokyo RDS endpoint — injected by Terraform; no local DB
DB_HOST = os.environ.get('DB_HOST', 'not-set')

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "region": "sa-east-1",
        "role": "compute-satellite",
        "phi_storage": False,
        "hostname": socket.gethostname()
    })

@app.route('/')
def index():
    return jsonify({
        "message": "Sao Paulo Flask App — stateless compute",
        "db_host": DB_HOST,
        "note": "This app connects to Tokyo RDS over TGW; no PHI stored here"
    })

@app.route('/api/public-feed')
def public_feed():
    return jsonify({
        "message": "Sao Paulo public feed",
        "region": "sa-east-1",
        "role": "compute-satellite"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
APPEOF

    # systemd manages the Flask process
    # unlike nohup, systemd restarts the app on crash and on reboot
    cat > /etc/systemd/system/flask.service << 'SVCEOF'
[Unit]
Description=Flask app — São Paulo stateless compute
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
Environment=DB_HOST=${data.terraform_remote_state.tokyo.outputs.tokyo_rds_endpoint}
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

    systemctl daemon-reload
    systemctl enable flask
    systemctl start flask
EOF

  tags = {
    Name       = "${var.project}-sao-paulo-app-ec2"
    Role       = "app-server"
    RegionRole = "compute-satellite"
    DataPolicy = "phi-japan-only"
  }

  depends_on = [aws_nat_gateway.sao_paulo_nat]
}

# ---------------------------------------------------------------------------
# ALB — São Paulo application load balancer
# Public-facing, routes to private EC2 on port 5000
# HTTP only for now — HTTPS requires CloudFront or ACM certificate
# CloudFront is planned but not deployed in current lab state
# ---------------------------------------------------------------------------

resource "aws_lb" "sao_paulo_alb" {
  name               = "${var.project}-sao-paulo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sao_paulo_alb_sg.id]
  subnets            = [aws_subnet.sao_paulo_public_1.id, aws_subnet.sao_paulo_public_2.id]

  tags = {
    Name = "${var.project}-sao-paulo-alb"
  }
}

resource "aws_lb_target_group" "sao_paulo_app_tg" {
  name     = "${var.project}-sao-paulo-app-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.sao_paulo_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project}-sao-paulo-app-tg"
  }
}

resource "aws_lb_target_group_attachment" "sao_paulo_app_attachment" {
  target_group_arn = aws_lb_target_group.sao_paulo_app_tg.arn
  target_id        = aws_instance.sao_paulo_app.id
  port             = 5000
}

resource "aws_lb_listener" "sao_paulo_http" {
  load_balancer_arn = aws_lb.sao_paulo_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sao_paulo_app_tg.arn
  }
}
