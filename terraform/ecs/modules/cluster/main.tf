# task role
resource "aws_iam_policy" "ecs_task_role_iam_policy" {
  path   = "/" # Path in which to create the policy
  policy = data.aws_iam_policy_document.ecs_task_role_iam_policy.json
}

resource "aws_iam_role" "ecs_task_role" {
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_role_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "task_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role_iam_policy.arn
}

# task execution role
resource "aws_iam_policy" "ecs_task_execution_role_iam_policy" {
  path   = "/" # Path in which to create the policy
  policy = data.aws_iam_policy_document.ecs_task_execution_role_iam_policy.json
}

resource "aws_iam_role" "ecs_task_execution_role" {
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_role_iam_policy.arn
}

resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "front_end_microservice" {
  family                   = "td-front-end-microservice-${local.name_suffix}"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = var.task_memory["front_end_microservice"]
  cpu                      = var.task_cpu["front_end_microservice"]

  container_definitions = jsonencode(
    [
      {
        "image" = var.container_images["front_end_microservice"]
        "name"  = "front-end-microservice-${local.name_suffix}"
        "portMappings" = [
          {
            "containerPort" = var.container_ports["front_end_microservice"]
          }
        ]
      }
  ])
}

resource "aws_security_group" "ecs_load_balanced_frontend_microservices" {
  name   = "${var.app_name}-sg-ecs-load-balanced-frontend-microservices-${var.stage_name}"
  vpc_id = var.vpcid

  ingress {
    from_port       = var.container_ports["front_end_microservice"]
    to_port         = var.container_ports["front_end_microservice"]
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "sg-ecs-load-balanced-frontend-microservices-${var.app_name}"
    Stage = var.stage_name
  }
}

resource "aws_ecs_service" "front_end_microservice" {
  name                              = "front-end-ecs-svc-${local.name_suffix}"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.front_end_microservice.arn
  desired_count                     = 2
  launch_type                       = "FARGATE"
  scheduling_strategy               = "REPLICA"
  health_check_grace_period_seconds = 147

  network_configuration {
    assign_public_ip = true
    subnets          = var.subnets
    security_groups  = [aws_security_group.ecs_load_balanced_frontend_microservices.id]
  }

  load_balancer {
    container_name   = "front-end-microservice-${local.name_suffix}"
    container_port   = var.container_ports["front_end_microservice"]
    target_group_arn = var.target_groups["front_end_microservice"]
  }
}
