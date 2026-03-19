resource "aws_db_subnet_group" "lab1c_rds" {
  name = "lab1c-rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_2a.id,
    aws_subnet.private_2b.id,
    aws_subnet.private_2c.id
  ]
  tags = {
    Name = "lab1c-rds-subnet-group"
  }
}