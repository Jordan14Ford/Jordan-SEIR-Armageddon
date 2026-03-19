output "monitoring_endpoint_id" { value = aws_vpc_endpoint.cloudyjones_monitoring.id }
output "ssm_endpoint_id"        { value = aws_vpc_endpoint.cloudyjones_ssm.id }
output "s3_endpoint_id"         { value = aws_vpc_endpoint.cloudyjones_s3.id }
