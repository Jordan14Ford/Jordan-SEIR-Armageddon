resource "aws_vpc_endpoint" "bedrock_runtime" {
  vpc_id            = aws_vpc.lab1c.id
  service_name      = "com.amazonaws.us-east-2.bedrock-runtime"
  vpc_endpoint_type = "Interface"
  
  subnet_ids = [
    aws_subnet.private_2a.id,
    aws_subnet.private_2b.id,
    aws_subnet.private_2c.id
  ]
  
  security_group_ids  = [aws_security_group.lab1c_private_ec2_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "lab1c-bedrock-runtime"
  }
}