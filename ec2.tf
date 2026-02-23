# IAM role for private EC2
resource "aws_iam_role" "cloudyjones_ec2_role01" {
  name = "${var.project}-ec2-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name    = "${var.project}-ec2-role01"
    Project = var.project
  }
}

# SSM managed policy — enables Session Manager access
resource "aws_iam_role_policy_attachment" "cloudyjones_ssm_policy" {
  role       = aws_iam_role.cloudyjones_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch agent policy — enables log shipping
resource "aws_iam_role_policy_attachment" "cloudyjones_cw_policy" {
  role       = aws_iam_role.cloudyjones_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Least privilege — Secrets Manager: only your specific secret
resource "aws_iam_role_policy" "cloudyjones_secrets_policy" {
  name = "${var.project}-secrets-policy"
  role = aws_iam_role.cloudyjones_ec2_role01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:lab/rds/mysql-*"
    }]
  })
}

# Least privilege — Parameter Store: only your specific path
resource "aws_iam_role_policy" "cloudyjones_ssm_params_policy" {
  name = "${var.project}-ssm-params-policy"
  role = aws_iam_role.cloudyjones_ec2_role01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters"]
      Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/lab/rds/*"
    }]
  })
}

# Instance profile — attaches role to EC2
resource "aws_iam_instance_profile" "cloudyjones_ec2_profile01" {
  name = "${var.project}-ec2-profile01"
  role = aws_iam_role.cloudyjones_ec2_role01.name
}

# Security group for private EC2
resource "aws_security_group" "cloudyjones_ec2_sg01" {
  name        = "${var.project}-ec2-sg01"
  description = "Security group for private EC2 instance"
  vpc_id      = aws_vpc.cloudyjones_vpc01.id

  # HTTP from within VPC only (ALB will forward here)
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-ec2-sg01"
    Project = var.project
  }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# Current account ID — used in IAM policy ARNs
data "aws_caller_identity" "current" {}

# Private EC2 — no public IP, SSM only
resource "aws_instance" "cloudyjones_ec201_private" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.cloudyjones_private_subnets[0].id
  iam_instance_profile   = aws_iam_instance_profile.cloudyjones_ec2_profile01.name
  vpc_security_group_ids = [aws_security_group.cloudyjones_ec2_sg01.id]

  # No public IP — private only
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip amazon-cloudwatch-agent

    pip3 install flask pymysql boto3

    cat > /home/ec2-user/app.py << 'APPEOF'
    from flask import Flask, request
    import pymysql
    import boto3
    import json

    app = Flask(__name__)

    def get_db_credentials():
        client = boto3.client('secretsmanager', region_name='${var.aws_region}')
        response = client.get_secret_value(SecretId='lab/rds/mysql')
        return json.loads(response['SecretString'])

    def get_db_connection():
        creds = get_db_credentials()
        return pymysql.connect(
            host=creds['host'],
            user=creds['username'],
            password=creds['password'],
            database=creds['dbname'],
            connect_timeout=5
        )

    @app.route('/')
    def home():
        return "<h1>cloudyjones — private EC2, Section A</h1>"

    @app.route('/health')
    def health():
        return {"status": "ok"}, 200

    @app.route('/list')
    def list_notes():
        try:
            connection = get_db_connection()
            with connection.cursor() as cursor:
                cursor.execute("USE labdb")
                cursor.execute("SELECT id, note, created_at FROM notes ORDER BY created_at DESC")
                notes = cursor.fetchall()
            connection.close()
            return {"notes": [{"id": n[0], "note": n[1]} for n in notes]}, 200
        except Exception as e:
            return {"error": str(e)}, 500

    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=80)
    APPEOF

    chown ec2-user:ec2-user /home/ec2-user/app.py

    cat > /etc/systemd/system/flask-app.service << 'SERVICEEOF'
    [Unit]
    Description=Flask App
    After=network.target

    [Service]
    User=root
    WorkingDirectory=/home/ec2-user
    ExecStart=/usr/bin/python3 /home/ec2-user/app.py
    Restart=always
    StandardOutput=append:/var/log/flask-app.log
    StandardError=append:/var/log/flask-app.log

    [Install]
    WantedBy=multi-user.target
    SERVICEEOF

    systemctl daemon-reload
    systemctl enable flask-app
    systemctl start flask-app
  EOF

  tags = {
    Name    = "${var.project}-ec2-private01"
    Project = var.project
  }
}