# RDS MySQL
# this is the only database - sao paulo connects here via TGW

# subnet group needs 2 AZs even for single-AZ RDS
resource "aws_db_subnet_group" "tokyo_db_subnet_group" {
  name        = "${var.project}-tokyo-db-subnet-group"
  description = "Private subnet group for Tokyo RDS - spans 1a and 1c, no public subnets"

  subnet_ids = [
    aws_subnet.tokyo_private_1.id, # ap-northeast-1a
    aws_subnet.tokyo_private_2.id  # ap-northeast-1c
  ]

  tags = {
    Name = "${var.project}-tokyo-db-subnet-group"
  }
}

resource "aws_db_parameter_group" "tokyo_db_params" {
  name        = "${var.project}-tokyo-mysql8-params"
  family      = "mysql8.0"
  description = "MySQL 8.0 parameter group for Tokyo Lab 3 RDS - using engine defaults"

  tags = {
    Name = "${var.project}-tokyo-mysql8-params"
  }
}

# the actual database
resource "aws_db_instance" "tokyo_rds" {
  identifier = "${var.project}-tokyo-mysql"

  engine               = "mysql"
  engine_version       = "8.0"
  parameter_group_name = aws_db_parameter_group.tokyo_db_params.name

  instance_class        = var.db_instance_class
  allocated_storage     = var.db_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.tokyo_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.tokyo_rds_sg.id]
  publicly_accessible    = false

  # multi_az = true  # would double the cost
  multi_az = false

  backup_retention_period = 1
  backup_window           = "18:00-19:00"
  maintenance_window      = "Mon:19:00-Mon:20:00"

  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name       = "${var.project}-tokyo-mysql"
    Compliance = "APPI"
    DataTier   = "primary" # Signals this is the only DB in the lab
  }
}
