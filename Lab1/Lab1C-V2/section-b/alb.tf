# Bonus-B — ALB, Target Group, HTTP→HTTPS redirect, SNS alarm, CloudWatch dashboard
# traffic flow: internet → ALB (public subnets, this module) → private EC2 (core module)

resource "aws_security_group" "cloudyjones_alb_sg01" {
  name        = "${var.project}-alb-sg01"
  description = "Allow HTTP and HTTPS from internet to ALB"
  vpc_id      = var.vpc_id

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

# Add ingress rule to EC2 SG via sg_rule to avoid a circular module dependency.
# Core creates EC2 SG without the ALB rule; section-b adds it here once
# the ALB SG exists.
resource "aws_security_group_rule" "cloudyjones_ec2_allow_from_alb" {
  type                     = "ingress"
  description              = "HTTP from ALB security group only"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cloudyjones_alb_sg01.id
  security_group_id        = var.ec2_sg_id
}

resource "aws_lb" "cloudyjones_alb01" {
  name               = "${var.project}-alb01"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.cloudyjones_alb_sg01.id]
  subnets            = var.public_subnet_ids

  access_logs {
    bucket  = var.alb_logs_bucket_name
    prefix  = "alb-access-logs"
    enabled = true
  }

  tags = {
    Name    = "${var.project}-alb01"
    Project = var.project
  }
}

resource "aws_lb_target_group" "cloudyjones_tg01" {
  name     = "${var.project}-tg01"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

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

resource "aws_lb_target_group_attachment" "cloudyjones_tg_attachment01" {
  target_group_arn = aws_lb_target_group.cloudyjones_tg01.arn
  target_id        = var.ec2_instance_id
  port             = 80
}

# HTTP:80 → HTTPS:443 redirect
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

# ALB 5xx alarm
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
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    LoadBalancer = aws_lb.cloudyjones_alb01.arn_suffix
  }

  tags = {
    Name    = "${var.project}-alb-5xx-alarm"
    Project = var.project
  }
}

# CloudWatch dashboard — 4 widgets: request count, 5xx, healthy hosts, response time
resource "aws_cloudwatch_dashboard" "cloudyjones_dashboard01" {
  dashboard_name = "${var.project}-dashboard01"

  dashboard_body = jsonencode({
    widgets = [
      { type = "metric", x = 0, y = 0, width = 12, height = 6,
        properties = { title = "ALB Request Count", region = var.aws_region, period = 60, stat = "Sum",
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.cloudyjones_alb01.arn_suffix]] } },
      { type = "metric", x = 12, y = 0, width = 12, height = 6,
        properties = { title = "ALB 5xx Errors", region = var.aws_region, period = 60, stat = "Sum",
          metrics = [["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", aws_lb.cloudyjones_alb01.arn_suffix]] } },
      { type = "metric", x = 0, y = 6, width = 12, height = 6,
        properties = { title = "Healthy Host Count", region = var.aws_region, period = 60, stat = "Average",
          metrics = [["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", aws_lb_target_group.cloudyjones_tg01.arn_suffix, "LoadBalancer", aws_lb.cloudyjones_alb01.arn_suffix]] } },
      { type = "metric", x = 12, y = 6, width = 12, height = 6,
        properties = { title = "Target Response Time", region = var.aws_region, period = 60, stat = "Average",
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.cloudyjones_alb01.arn_suffix]] } }
    ]
  })
}
