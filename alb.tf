# ============================================================
# alb.tf — Application Load Balancer, target group, listeners,
# SNS alerting, and CloudWatch dashboard
#
# traffic flow: internet → ALB (public subnets) → private EC2
# HTTP on port 80 gets redirected to HTTPS 443 automatically
# ============================================================

# ALB security group — open to internet on 80 and 443
# this is intentional, ALB is the public entry point
# EC2 security group only allows traffic FROM this SG, not from internet
resource "aws_security_group" "cloudyjones_alb_sg01" {
  name        = "${var.project}-alb-sg01"
  description = "Allow HTTP and HTTPS from internet to ALB"
  vpc_id      = aws_vpc.cloudyjones_vpc01.id

  ingress {
    description = "HTTP from internet - redirects to HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-alb-sg01"
    Project = var.project
  }
}

# ALB — internet-facing, spans both public subnets across AZs
# access_logs block ships every request to S3 for audit trail
# depends on the S3 bucket in logs.tf being created first
resource "aws_lb" "cloudyjones_alb01" {
  name               = "${var.project}-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cloudyjones_alb_sg01.id]
  subnets            = aws_subnet.cloudyjones_public_subnets[*].id

  access_logs {
    bucket  = aws_s3_bucket.cloudyjones_alb_logs_bucket01.bucket
    prefix  = "alb-access-logs"
    enabled = true
  }

  tags = {
    Name    = "${var.project}-alb01"
    Project = var.project
  }
}

# target group — ALB forwards traffic here, health check hits /health
# unhealthy_threshold = 3 means 3 failed checks before marking unhealthy
resource "aws_lb_target_group" "cloudyjones_tg01" {
  name     = "${var.project}-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.cloudyjones_vpc01.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name    = "${var.project}-tg01"
    Project = var.project
  }
}

# register the private EC2 as the target on port 80
resource "aws_lb_target_group_attachment" "cloudyjones_tg_attachment01" {
  target_group_arn = aws_lb_target_group.cloudyjones_tg01.arn
  target_id        = aws_instance.cloudyjones_ec201_private.id
  port             = 80
}

# HTTP listener — any request on port 80 gets a 301 redirect to HTTPS
# this ensures all traffic is encrypted in transit
resource "aws_lb_listener" "cloudyjones_http_listener01" {
  load_balancer_arn = aws_lb.cloudyjones_alb01.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# SNS topic — alarm notifications go here, then fan out to email
resource "aws_sns_topic" "cloudyjones_sns_topic01" {
  name = "${var.project}-sns-topic01"

  tags = {
    Name    = "${var.project}-sns-topic01"
    Project = var.project
  }
}

# email subscription — you have to confirm this in your inbox after apply
resource "aws_sns_topic_subscription" "cloudyjones_sns_email01" {
  topic_arn = aws_sns_topic.cloudyjones_sns_topic01.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch alarm — triggers when ALB returns 10+ 5xx errors in 2 minutes
# fires to SNS which sends an email alert
resource "aws_cloudwatch_metric_alarm" "cloudyjones_alb_5xx" {
  alarm_name          = "${var.project}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB returning 5xx errors - check target health and app logs"
  alarm_actions       = [aws_sns_topic.cloudyjones_sns_topic01.arn]

  dimensions = {
    LoadBalancer = aws_lb.cloudyjones_alb01.arn_suffix
  }

  tags = {
    Name    = "${var.project}-alb-5xx-alarm"
    Project = var.project
  }
}

# CloudWatch dashboard — 4 widgets showing key ALB metrics
# request count, 5xx errors, healthy host count, response time
# useful for spotting issues at a glance without digging through logs
resource "aws_cloudwatch_dashboard" "cloudyjones_dashboard01" {
  dashboard_name = "${var.project}-dashboard01"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = var.aws_region
          period = 60
          stat   = "Sum"
          metrics = [["AWS/ApplicationELB", "RequestCount",
          "LoadBalancer", aws_lb.cloudyjones_alb01.arn_suffix]]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "ALB 5xx Errors"
          region = var.aws_region
          period = 60
          stat   = "Sum"
          metrics = [["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count",
          "LoadBalancer", aws_lb.cloudyjones_alb01.arn_suffix]]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Healthy Host Count"
          region = var.aws_region
          period = 60
          stat   = "Average"
          metrics = [["AWS/ApplicationELB", "HealthyHostCount",
          "TargetGroup", aws_lb_target_group.cloudyjones_tg01.arn_suffix,
          "LoadBalancer", aws_lb.cloudyjones_alb01.arn_suffix]]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Target Response Time"
          region = var.aws_region
          period = 60
          stat   = "Average"
          metrics = [["AWS/ApplicationELB", "TargetResponseTime",
          "LoadBalancer", aws_lb.cloudyjones_alb01.arn_suffix]]
        }
      }
    ]
  })
}