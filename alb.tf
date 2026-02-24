# Security group for ALB — public facing
resource "aws_security_group" "cloudyjones_alb_sg01" {
  name        = "${var.project}-alb-sg01"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.cloudyjones_vpc01.id

  ingress {
    description = "HTTP from internet"
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

# Target group — points to private EC2 on port 80
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

# Register private EC2 as target
resource "aws_lb_target_group_attachment" "cloudyjones_tg_attachment01" {
  target_group_arn = aws_lb_target_group.cloudyjones_tg01.arn
  target_id        = aws_instance.cloudyjones_ec201_private.id
  port             = 80
}

# HTTP listener — redirects to HTTPS
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

# SNS topic for alerts
resource "aws_sns_topic" "cloudyjones_sns_topic01" {
  name = "${var.project}-sns-topic01"

  tags = {
    Name    = "${var.project}-sns-topic01"
    Project = var.project
  }
}

# SNS email subscription
resource "aws_sns_topic_subscription" "cloudyjones_sns_email01" {
  topic_arn = aws_sns_topic.cloudyjones_sns_topic01.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch alarm — fires on ALB 5xx spike
resource "aws_cloudwatch_metric_alarm" "cloudyjones_alb_5xx" {
  alarm_name          = "${var.project}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5xx error spike"
  alarm_actions       = [aws_sns_topic.cloudyjones_sns_topic01.arn]

  dimensions = {
    LoadBalancer = aws_lb.cloudyjones_alb01.arn_suffix
  }

  tags = {
    Name    = "${var.project}-alb-5xx-alarm"
    Project = var.project
  }
}

# CloudWatch Dashboard
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