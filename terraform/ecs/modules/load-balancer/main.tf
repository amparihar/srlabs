locals {
  name_suffix = "${var.app_name}-${var.stage_name}"
}

resource "aws_lb" "main" {
  count              = var.create_alb ? 1 : 0
  name               = "alb-ecs-${var.app_name}-${var.stage_name}"
  internal           = false
  load_balancer_type = "application"
  # mandatory for alb
  security_groups = [aws_security_group.alb.id]
  subnets         = var.subnets

  tags = {
    Name  = "alb-${var.app_name}-${count.index + 1}"
    Stage = var.stage_name
  }

  depends_on = [
    aws_security_group.alb
  ]
}

# load balancer security group
resource "aws_security_group" "alb" {
  name   = "${var.app_name}-sg-alb-ecs-${var.stage_name}"
  vpc_id = var.vpcid

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name  = "sg-alb-ecs-${var.app_name}"
    Stage = var.stage_name
  }
}

# target group
resource "aws_lb_target_group" "tg_front_end_microservice" {
  name        = substr("tg-front-end-ecs-svc-${local.name_suffix}", 0, min(32, length("tg-front-end-ecs-svc-${local.name_suffix}")))
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpcid

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2
    interval            = 30
    timeout             = 10
    protocol            = "HTTP"
    matcher             = "200"
    path                = var.target_group_health_check_path["front_end_microservice"]
  }

  tags = {
    Name  = "tg-front-end-ecs-svc-${var.app_name}"
    Stage = var.stage_name
  }
}

# http listener with default action
resource "aws_lb_listener" "microservice" {
  load_balancer_arn = aws_lb.main[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "The path you are looking for is unavaliable"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "front_end_microservice" {
  listener_arn = aws_lb_listener.microservice.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_front_end_microservice.arn
  }
  condition {
    path_pattern {
      values = var.listener_path_patterns["front_end_microservice"]
    }
  }
}

output "arn" {
  value = aws_lb.main.*.arn
}

output "dns_name" {
  value = aws_lb.main.*.dns_name
}

output "security_group_id" {
  value = aws_security_group.alb.id
}

output "front_end_microservice_target_group_arn" {
  value = aws_lb_target_group.tg_front_end_microservice.arn
}
