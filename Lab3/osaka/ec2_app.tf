# osaka EC2 and ALB - failover for tokyo

# IAM role for SSM
resource "aws_iam_role" "osaka_ec2_role" {
  name = "${var.project}-osaka-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.project}-osaka-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "osaka_ssm" {
  role       = aws_iam_role.osaka_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "osaka_cloudwatch" {
  role       = aws_iam_role.osaka_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "osaka_ec2_profile" {
  name = "${var.project}-osaka-ec2-profile"
  role = aws_iam_role.osaka_ec2_role.name
}

# EC2 instance - connects to Tokyo RDS via TGW
resource "aws_instance" "osaka_app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.osaka_private_1.id
  vpc_security_group_ids = [aws_security_group.osaka_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.osaka_ec2_profile.name

  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip

    pip3 install flask pymysql boto3

    mkdir -p /opt/app
    cat > /opt/app/app.py << 'APPEOF'
from flask import Flask, jsonify
import socket
import os

app = Flask(__name__)

DB_HOST = os.environ.get('DB_HOST', '${var.tokyo_rds_endpoint}')

@app.route('/')
def home():
    return jsonify({
        "message": "Osaka Flask App (Failover)",
        "db_host": DB_HOST,
        "note": "This app connects to Tokyo RDS over TGW"
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "region": "ap-northeast-3",
        "role": "dr-failover",
        "phi_storage": False,
        "hostname": socket.gethostname()
    })

@app.route('/api/public-feed')
def public_feed():
    return jsonify({"message": "Osaka public feed (failover)", "region": "ap-northeast-3"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
APPEOF

    # systemd service for auto-restart
    cat > /etc/systemd/system/flask.service << 'SVCEOF'
[Unit]
Description=Flask App
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/app
Environment=DB_HOST=${var.tokyo_rds_endpoint}
ExecStart=/usr/bin/python3 /opt/app/app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SVCEOF

    systemctl daemon-reload
    systemctl enable flask
    systemctl start flask
EOF

  tags = {
    Name       = "${var.project}-osaka-app-ec2"
    Role       = "failover-app-server"
    RegionRole = "dr-failover"
    DataPolicy = "phi-japan-only"
  }
}

# ALB
resource "aws_lb" "osaka_alb" {
  name               = "${var.project}-osaka-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.osaka_alb_sg.id]

  subnets = [
    aws_subnet.osaka_public_1.id,
    aws_subnet.osaka_public_2.id
  ]

  tags = {
    Name = "${var.project}-osaka-alb"
    Role = "failover"
  }
}

resource "aws_lb_target_group" "osaka_tg" {
  name     = "${var.project}-osaka-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.osaka_vpc.id

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
    Name = "${var.project}-osaka-tg"
  }
}

resource "aws_lb_target_group_attachment" "osaka_app_attachment" {
  target_group_arn = aws_lb_target_group.osaka_tg.arn
  target_id        = aws_instance.osaka_app.id
  port             = 5000
}

resource "aws_lb_listener" "osaka_http" {
  load_balancer_arn = aws_lb.osaka_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.osaka_tg.arn
  }
}
