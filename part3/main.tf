# ECR Repositories
module "flask_ecr" {
  source          = "../modules/ecr"
  repository_name = "flask-app"
}

module "express_ecr" {
  source          = "../modules/ecr"
  repository_name = "express-app"
}

# IAM Roles for ECS
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name   = "part3-alb-sg"
  vpc_id = var.vpc_id

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
}

resource "aws_security_group" "ecs_sg" {
  name   = "part3-ecs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
module "alb" {
  source          = "../modules/alb"
  alb_name        = "part3-alb"
  security_groups = [aws_security_group.alb_sg.id]
  subnets         = var.public_subnet_ids
}

# Target Groups
resource "aws_lb_target_group" "flask_tg" {
  name        = "flask-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/api"
  }
}

resource "aws_lb_target_group" "express_tg" {
  name        = "express-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

# ALB Listener Rules
resource "aws_lb_listener_rule" "flask_rule" {
  listener_arn = module.alb.listener_arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api", "/api/*"]
    }
  }
}

resource "aws_lb_listener_rule" "express_rule" {
  listener_arn = module.alb.listener_arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.express_tg.arn
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

# ECS Services
module "flask_service" {
  source             = "../modules/ecs"
  cluster_name       = "part3-cluster"
  service_name       = "flask-service"
  family             = "flask-task"
  container_name     = "flask-app"
  image              = "${module.flask_ecr.repository_url}:latest"
  container_port     = 5000
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_execution_role.arn
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = var.public_subnet_ids
  target_group_arn   = aws_lb_target_group.flask_tg.arn
}

module "express_service" {
  source             = "../modules/ecs"
  cluster_name       = "part3-cluster"
  service_name       = "express-service"
  family             = "express-task"
  container_name     = "express-app"
  image              = "${module.express_ecr.repository_url}:latest"
  container_port     = 3000
  execution_role_arn = aws_iam_role.ecs_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_execution_role.arn
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = var.public_subnet_ids
  target_group_arn   = aws_lb_target_group.express_tg.arn
  environment = [
    {
      name  = "BACKEND_URL"
      value = "http://${module.alb.alb_dns_name}"
    }
  ]
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}
