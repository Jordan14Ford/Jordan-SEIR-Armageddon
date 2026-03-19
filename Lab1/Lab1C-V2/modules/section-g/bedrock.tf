# Bonus-G — Bedrock Auto-IR pipeline
# flow: SNS alarm fires → Lambda → CW Insights queries (WAF + app) → Bedrock report → S3 + SNS notify

resource "aws_s3_bucket" "cloudyjones_ir_reports_bucket01" {
  bucket        = "${var.project}-ir-reports-${var.account_id}"
  force_destroy = true

  tags = {
    Name    = "${var.project}-ir-reports-bucket01"
    Project = var.project
  }
}

resource "aws_s3_bucket_public_access_block" "cloudyjones_ir_reports_pab01" {
  bucket                  = aws_s3_bucket.cloudyjones_ir_reports_bucket01.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "cloudyjones_ir_lambda_role01" {
  name = "${var.project}-ir-lambda-role01"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "cloudyjones_ir_lambda_policy01" {
  name = "${var.project}-ir-lambda-policy01"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:StartQuery", "logs:GetQueryResults", "logs:DescribeLogStreams", "logs:FilterLogEvents"]
        Resource = ["${var.app_log_group_arn}:*", "${var.waf_log_group_arn}:*"]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/lab/db/*"
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = [var.db_secret_arn, "${var.db_secret_arn}*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${aws_s3_bucket.cloudyjones_ir_reports_bucket01.arn}/reports/*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.sns_topic_arn
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudyjones_ir_lambda_attach01" {
  role       = aws_iam_role.cloudyjones_ir_lambda_role01.name
  policy_arn = aws_iam_policy.cloudyjones_ir_lambda_policy01.arn
}

resource "aws_iam_role_policy_attachment" "cloudyjones_ir_lambda_basiclogs01" {
  role       = aws_iam_role.cloudyjones_ir_lambda_role01.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "cloudyjones_ir_lambda_zip01" {
  type        = "zip"
  source_file = "${path.module}/lambda/handler.py"
  output_path = "${path.module}/lambda/handler.zip"
}

resource "aws_lambda_function" "cloudyjones_ir_lambda01" {
  function_name    = "${var.project}-ir-autoreport01"
  role             = aws_iam_role.cloudyjones_ir_lambda_role01.arn
  runtime          = "python3.12"
  handler          = "handler.lambda_handler"
  timeout          = 30
  filename         = data.archive_file.cloudyjones_ir_lambda_zip01.output_path
  source_code_hash = data.archive_file.cloudyjones_ir_lambda_zip01.output_base64sha256

  environment {
    variables = {
      REPORT_BUCKET    = aws_s3_bucket.cloudyjones_ir_reports_bucket01.bucket
      APP_LOG_GROUP    = var.app_log_group_name
      WAF_LOG_GROUP    = var.waf_log_group_name
      SECRET_ID        = var.db_secret_name
      SSM_PARAM_PATH   = "/lab/db/"
      BEDROCK_MODEL_ID = var.bedrock_model_id
      SNS_TOPIC_ARN    = var.sns_topic_arn
    }
  }
}

resource "aws_sns_topic_subscription" "cloudyjones_ir_lambda_sub01" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.cloudyjones_ir_lambda01.arn
}

resource "aws_lambda_permission" "cloudyjones_allow_sns_invoke01" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudyjones_ir_lambda01.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}
