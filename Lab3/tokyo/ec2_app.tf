# EC2 and ALB — Tokyo (ap-northeast-1)
# Role: data authority region — only region with RDS
# All PHI reads/writes originate or terminate here

# ---------------------------------------------------------------------------
# IAM — instance role for Tokyo EC2
# Follows least-privilege: SSM for access, CloudWatch for logs,
# Secrets Manager read-only for RDS credentials
# Note: ReadOnly only — EC2 has no reason to write or rotate secrets
# ---------------------------------------------------------------------------

resource "aws_iam_role" "tokyo_ec2_role" {
  name = "${var.project}-tokyo-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project}-tokyo-ec2-role"
  }
}

# SSM — no SSH keys needed, access via Session Manager
resource "aws_iam_role_policy_attachment" "tokyo_ssm" {
  role       = aws_iam_role.tokyo_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch — app and system logs
resource "aws_iam_role_policy_attachment" "tokyo_cloudwatch" {
  role       = aws_iam_role.tokyo_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Secrets Manager — read-only for RDS credential
# AWS has no managed "SecretsManagerReadOnly" policy; use inline policy so EC2
# can only GetSecretValue (no write/rotate). ReadWrite would be overkill.
resource "aws_iam_role_policy" "tokyo_secrets_read" {
  name   = "${var.project}-tokyo-secrets-read"
  role   = aws_iam_role.tokyo_ec2_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:*:secret:${var.project}-tokyo-db-secret*"
    }]
  })
}

resource "aws_iam_instance_profile" "tokyo_ec2_profile" {
  name = "${var.project}-tokyo-ec2-profile"
  role = aws_iam_role.tokyo_ec2_role.name
}

# ---------------------------------------------------------------------------
# EC2 — Tokyo app instance
# Private subnet only — no public IP
# Access via SSM Session Manager, not SSH
# App managed by systemd (not nohup) — survives reboots and crashes
#
# Debugging tip: if the app doesn't start after launch, check:
#   /var/log/cloud-init-output.log  — bootstrap script output
#   journalctl -u flask             — systemd service logs
# ---------------------------------------------------------------------------

resource "aws_instance" "tokyo_app" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.tokyo_private_1.id
  vpc_security_group_ids      = [aws_security_group.tokyo_ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.tokyo_ec2_profile.name
  associate_public_ip_address = false

  # user_data runs once on first boot via cloud-init
  # <<-EOF strips leading spaces from content lines
  # closing EOF must be flush-left at column zero — bash won't match it otherwise
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip mysql

    pip3 install flask pymysql boto3

    mkdir -p /opt/app

    # Python content must be flush-left inside this heredoc
    # <<-EOF strips the outer indentation but APPEOF content
    # is written to disk exactly as it appears here
    # indented Python = IndentationError on startup
    cat > /opt/app/app.py << 'APPEOF'
from flask import Flask, jsonify
import pymysql
import boto3
import json
import os

app = Flask(__name__)

def get_db_connection():
    # Credentials fetched from Secrets Manager at runtime
    # Never hardcoded — this is the APPI-compliant pattern
    client = boto3.client('secretsmanager', region_name='ap-northeast-1')
    secret = json.loads(
        client.get_secret_value(SecretId='lab3-tokyo-db-secret')['SecretString']
    )
    return pymysql.connect(
        host=os.environ.get('DB_HOST', ''),
        user=secret['username'],
        password=secret['password'],
        database=secret['dbname'],
        cursorclass=pymysql.cursors.DictCursor
    )

@app.route('/health')
def health():
    # Signals region role and PHI storage status explicitly
    return jsonify({
        "status": "healthy",
        "region": "ap-northeast-1",
        "role": "data-authority",
        "phi_storage": True
    })

@app.route('/api/public-feed')
def public_feed():
    return jsonify({
        "message": "Tokyo public feed",
        "region": "ap-northeast-1"
    })

@app.route('/db-check')
def db_check():
    # Live RDS connectivity check — used in audit verification
    try:
        conn = get_db_connection()
        conn.close()
        return jsonify({"db": "reachable", "region": "ap-northeast-1"})
    except Exception as e:
        return jsonify({"db": "unreachable", "error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
APPEOF

    # systemd manages the Flask process
    # unlike nohup, systemd restarts the app on crash and on reboot
    # Tokyo is the data authority — it needs to be the most resilient instance
    cat > /etc/systemd/system/flask.service << 'SVCEOF'
[Unit]
Description=Flask app — Tokyo data authority
After=network.target

[Service]
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
    Name        = "${var.project}-tokyo-app-ec2"
    Role        = "app-server"
    RegionRole  = "data-authority"
    DataPolicy  = "phi-japan-only"
  }
}

# ---------------------------------------------------------------------------
# ALB — Tokyo application load balancer
# Public-facing, routes to private EC2 on port 5000
# Health check on /health — Flask must be running for ALB to mark healthy
# ---------------------------------------------------------------------------

resource "aws_lb" "tokyo_alb" {
  name               = "${var.project}-tokyo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tokyo_alb_sg.id]

  subnets = [
    aws_subnet.tokyo_public_1.id,
    aws_subnet.tokyo_public_2.id
  ]

  tags = {
    Name = "${var.project}-tokyo-alb"
  }
}

resource "aws_lb_target_group" "tokyo_tg" {
  name     = "${var.project}-tokyo-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.tokyo_vpc.id

  health_check {
    path                = "/health"
    port                = "5000"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = {
    Name = "${var.project}-tokyo-tg"
  }
}

resource "aws_lb_target_group_attachment" "tokyo_app_attachment" {
  target_group_arn = aws_lb_target_group.tokyo_tg.arn
  target_id        = aws_instance.tokyo_app.id
  port             = 5000
}

# HTTP only for now — HTTPS requires CloudFront or ACM certificate
# CloudFront is planned but not deployed in current lab state
resource "aws_lb_listener" "tokyo_http" {
  load_balancer_arn = aws_lb.tokyo_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tokyo_tg.arn
  }
}
