output "ir_reports_bucket" { value = aws_s3_bucket.cloudyjones_ir_reports_bucket01.bucket }
output "ir_lambda_name"    { value = aws_lambda_function.cloudyjones_ir_lambda01.function_name }
