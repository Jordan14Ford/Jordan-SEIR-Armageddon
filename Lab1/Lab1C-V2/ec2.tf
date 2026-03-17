# ============================================================
# ec2.tf — private EC2 instance with IAM role, security group,
# and Flask app deployed via user_data
#
# key pattern: no public IP, no SSH, no key pair
# only access method is SSM Session Manager via VPC endpoints
# ============================================================

# IAM role — EC2 assumes this role at launch
# trust policy says only EC2 service can assume it
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

# AWS managed policy for SSM Session Manager
# gives the instance permission to register with SSM and accept sessions
resource "aws_iam_role_policy_attachment" "cloudyjones_ssm_policy" {
  role       = aws_iam_role.cloudyjones_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# AWS managed policy for CloudWatch agent
# allows the instance to ship logs and metrics to CloudWatch
resource "aws_iam_role_policy_attachment" "cloudyjones_cw_policy" {
  role       = aws_iam_role.cloudyjones_ec2_role01.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# least privilege: only allow access to the specific secret this app needs
# using a wildcard on the secret name suffix because AWS appends a random string
resource "aws_iam_role_policy" "cloudyjones_secrets_policy" {
  name = "${var.project}-secrets-policy"
  role = aws_iam_role.cloudyjones_ec2_role01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Resource = [
        aws_secretsmanager_secret.cloudyjones_db_secret01.arn,
        "${aws_secretsmanager_secret.cloudyjones_db_secret01.arn}*"
      ]
    }]
  })
}

# least privilege: only allow reads from /lab/rds/* parameter path
# not giving access to all SSM parameters, just what the app needs
resource "aws_iam_role_policy" "cloudyjones_ssm_params_policy" {
  name = "${var.project}-ssm-params-policy"
  role = aws_iam_role.cloudyjones_ec2_role01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter", "ssm:GetParameters"]
      Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
    }]
  })
}

resource "aws_iam_role_policy" "cloudyjones_put_metric_policy" {
  name = "${var.project}-cw-putmetric-policy"
  role = aws_iam_role.cloudyjones_ec2_role01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudwatch:PutMetricData"]
      Resource = "*"
      Condition = {
        StringEquals = {
          "cloudwatch:namespace" = "Lab/RDSApp"
        }
      }
    }]
  })
}

# instance profile wraps the role so EC2 can use it
# EC2 can't use an IAM role directly, needs the profile as a container
resource "aws_iam_instance_profile" "cloudyjones_ec2_profile01" {
  name = "${var.project}-ec2-profile01"
  role = aws_iam_role.cloudyjones_ec2_role01.name
}

# EC2 security group — only allows port 80 from within the VPC
# ALB forwards traffic here after terminating TLS
# no SSH port open, no public access
resource "aws_security_group" "cloudyjones_ec2_sg01" {
  name        = "${var.project}-ec2-sg01"
  description = "Allow HTTP from VPC only - ALB forwards here"
  vpc_id      = aws_vpc.cloudyjones_vpc01.id

  ingress {
    description     = "HTTP from ALB security group only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.cloudyjones_alb_sg01.id]
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

# get the latest Amazon Linux 2023 AMI dynamically
# this avoids hardcoding an AMI ID that gets stale over time
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

data "aws_caller_identity" "current" {}

# private EC2 — no public IP, no key pair, SSM only
# user_data installs Flask app and sets it up as a systemd service
# note: pip3 install will fail if run before VPC endpoints are up
# if Flask doesn't start, check: sudo systemctl status flask-app
resource "aws_instance" "cloudyjones_ec201_private" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.cloudyjones_private_subnets[0].id
  iam_instance_profile        = aws_iam_instance_profile.cloudyjones_ec2_profile01.name
  vpc_security_group_ids      = [aws_security_group.cloudyjones_ec2_sg01.id]
  associate_public_ip_address = false

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y python3 python3-pip amazon-cloudwatch-agent
    pip3 install --upgrade pip
    pip3 install flask pymysql boto3

    cat > /home/ec2-user/app.py << 'APPEOF'
    from flask import Flask, request
    import pymysql
    import boto3
    import json
    import os
    import logging

    app = Flask(__name__)
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("lab1c-app")

    REGION = os.environ.get("AWS_REGION", "${var.aws_region}")
    SECRET_ID = os.environ.get("SECRET_ID", "lab/rds/mysql")
    DB_ENDPOINT_PARAM = os.environ.get("DB_ENDPOINT_PARAM", "/lab/db/endpoint")
    DB_PORT_PARAM = os.environ.get("DB_PORT_PARAM", "/lab/db/port")
    DB_NAME_PARAM = os.environ.get("DB_NAME_PARAM", "/lab/db/name")

    ssm = boto3.client("ssm", region_name=REGION)
    secrets = boto3.client("secretsmanager", region_name=REGION)
    cloudwatch = boto3.client("cloudwatch", region_name=REGION)

    def emit_db_error_metric():
        cloudwatch.put_metric_data(
            Namespace="Lab/RDSApp",
            MetricData=[{
                "MetricName": "DBConnectionErrors",
                "Value": 1,
                "Unit": "Count"
            }]
        )

    def get_ssm_values():
        response = ssm.get_parameters(
            Names=[DB_ENDPOINT_PARAM, DB_PORT_PARAM, DB_NAME_PARAM],
            WithDecryption=True
        )
        values = {p["Name"]: p["Value"] for p in response.get("Parameters", [])}
        return {
            "host": values.get(DB_ENDPOINT_PARAM),
            "port": int(values.get(DB_PORT_PARAM, "3306")),
            "dbname": values.get(DB_NAME_PARAM, "labdb")
        }

    def get_secret_values():
        response = secrets.get_secret_value(SecretId=SECRET_ID)
        value = json.loads(response["SecretString"])
        return {
            "username": value["username"],
            "password": value["password"],
            "host": value.get("host"),
            "port": int(value.get("port", 3306)),
            "dbname": value.get("dbname", "labdb")
        }

    def build_db_config():
        secret_cfg = get_secret_values()
        ssm_cfg = get_ssm_values()
        return {
            "host": ssm_cfg["host"] or secret_cfg["host"],
            "port": ssm_cfg["port"] or secret_cfg["port"],
            "dbname": ssm_cfg["dbname"] or secret_cfg["dbname"],
            "username": secret_cfg["username"],
            "password": secret_cfg["password"]
        }

    def get_db_connection():
        cfg = build_db_config()
        return pymysql.connect(
            host=cfg["host"],
            user=cfg["username"],
            password=cfg["password"],
            database=cfg["dbname"],
            port=int(cfg["port"]),
            autocommit=True,
            connect_timeout=5
        )

    @app.route('/')
    def home():
        return "<h2>Lab1C app online</h2><p>/init, /add?note=hello, /list</p>"

    @app.route('/health')
    def health():
        return {"status": "ok"}, 200

    @app.route('/init')
    def init():
        cfg = build_db_config()
        conn = pymysql.connect(
            host=cfg["host"],
            user=cfg["username"],
            password=cfg["password"],
            port=int(cfg["port"]),
            autocommit=True
        )
        with conn.cursor() as cur:
            cur.execute(f"CREATE DATABASE IF NOT EXISTS `{cfg['dbname']}`;")
            cur.execute(f"USE `{cfg['dbname']}`;")
            cur.execute("""
                CREATE TABLE IF NOT EXISTS notes (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    note VARCHAR(255) NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );
            """)
        conn.close()
        return {"status": "initialized", "db": cfg["dbname"]}, 200

    @app.route('/add')
    def add():
        note = request.args.get("note", "").strip()
        if not note:
            return {"error": "missing note parameter"}, 400
        try:
            connection = get_db_connection()
            with connection.cursor() as cursor:
                cursor.execute(
                    "INSERT INTO notes(note, created_at) VALUES(%s, CURRENT_TIMESTAMP)",
                    (note,)
                )
            connection.close()
            return {"status": "inserted", "note": note}, 200
        except Exception as exc:
            logger.exception("ERROR: DB insert failed")
            emit_db_error_metric()
            return {"error": f"db insert failed: {exc}"}, 500

    @app.route('/list')
    def list_notes():
        try:
            connection = get_db_connection()
            with connection.cursor() as cursor:
                cursor.execute("SELECT id, note, created_at FROM notes ORDER BY created_at DESC")
                notes = cursor.fetchall()
            connection.close()
            return {"notes": [{"id": n[0], "note": n[1]} for n in notes]}, 200
        except Exception as exc:
            logger.exception("ERROR: DB list failed")
            emit_db_error_metric()
            return {"error": f"db list failed: {exc}"}, 500

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
    Environment=AWS_REGION=${var.aws_region}
    Environment=SECRET_ID=lab/rds/mysql
    Environment=DB_ENDPOINT_PARAM=/lab/db/endpoint
    Environment=DB_PORT_PARAM=/lab/db/port
    Environment=DB_NAME_PARAM=/lab/db/name
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

    mkdir -p /opt/aws/amazon-cloudwatch-agent/etc
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWEOF'
    {
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/flask-app.log",
                "log_group_name": "/aws/ec2/${var.project}-rds-app",
                "log_stream_name": "{instance_id}",
                "retention_in_days": 7
              }
            ]
          }
        }
      }
    }
    CWEOF
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
  EOF

  tags = {
    Name    = "${var.project}-ec2-private01"
    Project = var.project
  }
}