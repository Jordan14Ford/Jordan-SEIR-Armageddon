resource "aws_db_instance" "lab1c_mysql" {
  identifier     = "lab1c-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name                     = "lab1c_db"
  username                    = "admin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.lab1c_rds.name
  vpc_security_group_ids = [aws_security_group.lab1c_rds_sg.id]
  publicly_accessible    = false

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  tags = {
    Name = "lab1c-mysql"
  }
}

output "rds_endpoint" {
  value = aws_db_instance.lab1c_mysql.endpoint
}

output "rds_secret_arn" {
  value = aws_db_instance.lab1c_mysql.master_user_secret[0].secret_arn
}