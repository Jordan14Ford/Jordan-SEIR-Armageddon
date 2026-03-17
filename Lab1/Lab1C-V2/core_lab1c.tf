resource "aws_security_group" "cloudyjones_rds_sg01" {
  name        = "${var.project}-rds-sg01"
  description = "Allow MySQL from app EC2 only"
  vpc_id      = aws_vpc.cloudyjones_vpc01.id

  ingress {
    description     = "MySQL from EC2 app SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.cloudyjones_ec2_sg01.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-rds-sg01"
    Project = var.project
  }
}

resource "aws_db_subnet_group" "cloudyjones_rds_subnet_group01" {
  name       = "${var.project}-rds-subnet-group01"
  subnet_ids = aws_subnet.cloudyjones_private_subnets[*].id

  tags = {
    Name    = "${var.project}-rds-subnet-group01"
    Project = var.project
  }
}

resource "aws_db_instance" "cloudyjones_rds01" {
  identifier     = "${var.project}-rds01"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  publicly_accessible    = false
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.cloudyjones_rds_subnet_group01.name
  vpc_security_group_ids = [aws_security_group.cloudyjones_rds_sg01.id]

  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1

  tags = {
    Name    = "${var.project}-rds01"
    Project = var.project
  }
}

resource "aws_ssm_parameter" "cloudyjones_db_endpoint_param" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.cloudyjones_rds01.address
}

resource "aws_ssm_parameter" "cloudyjones_db_port_param" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.cloudyjones_rds01.port)
}

resource "aws_ssm_parameter" "cloudyjones_db_name_param" {
  name  = "/lab/db/name"
  type  = "String"
  value = var.db_name
}

resource "aws_secretsmanager_secret" "cloudyjones_db_secret01" {
  name = "lab/rds/mysql"

  tags = {
    Name    = "${var.project}-db-secret01"
    Project = var.project
  }
}

resource "aws_secretsmanager_secret_version" "cloudyjones_db_secret_version01" {
  secret_id = aws_secretsmanager_secret.cloudyjones_db_secret01.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = aws_db_instance.cloudyjones_rds01.address
    port     = aws_db_instance.cloudyjones_rds01.port
    dbname   = var.db_name
  })
}

resource "aws_cloudwatch_log_group" "cloudyjones_app_log_group01" {
  name              = "/aws/ec2/${var.project}-rds-app"
  retention_in_days = 7

  tags = {
    Name    = "${var.project}-app-log-group01"
    Project = var.project
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudyjones_db_connection_failure_alarm01" {
  alarm_name          = "${var.project}-db-connection-failure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "DB connectivity errors are elevated"
  alarm_actions       = [aws_sns_topic.cloudyjones_sns_topic01.arn]

  tags = {
    Name    = "${var.project}-db-connection-failure"
    Project = var.project
  }
}
