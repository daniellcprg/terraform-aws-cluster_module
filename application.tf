resource "aws_ecr_repository" "main" {
  count = length(var.applications)

  name = format(
    "%s-%s-%s",
    var.applications[count.index].name,
    var.applications[count.index].type,
    var.cluster_environment
  )

  tags = {
    "Provider"    = "terraform"
    "Environment" = var.cluster_environment,
  }
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = format(
    "/ecs/%s-%s-%s",
    var.applications[count.index].name,
    var.applications[count.index].type,
    var.cluster_environment
  )

  tags = {
    Environment = var.cluster_environment,
  }
}

resource "aws_ecs_task_definition" "td" {
  count = length(var.applications)

  family = format(
    "%s-%s-%s",
    var.applications[count.index].name,
    var.applications[count.index].type,
    var.cluster_environment
  )

  container_definitions = jsonencode([
    {
      name = format(
        "%s-%s-%s",
        var.applications[count.index].name,
        var.applications[count.index].type,
        var.cluster_environment
      ),
      image     = aws_ecr_repository.main[count.index].repository_url,
      memory    = 64
      essential = true
      portMappings = [
        {
          containerPort = var.applications[count.index].port
          hostPort      = var.applications[count.index].port
        }
      ],
      environment = [
        {
          name  = "NODE_ENV",
          value = var.cluster_environment
        }
      ],
      logConfiguration = {
        logDriver     = "awslogs",
        secretOptions = null,
        options = {
          "awslogs-group" : format(
            "/ecs/%s-%s-%s",
            var.applications[count.index].name,
            var.applications[count.index].type,
            var.cluster_environment
          ),
          "awslogs-region" : "us-east-1",
          "awslogs-stream-prefix" : "ecs"
        }
      },
    },
  ])

  tags = {
    "Provider"    = "terraform"
    "Environment" = var.cluster_environment,
  }
}

resource "aws_ecs_service" "ecs-service" {
  count = length(var.applications)

  name = format(
    "%s-%s-%s",
    var.applications[count.index].name,
    var.applications[count.index].type,
    var.cluster_environment
  )
  cluster         = var.cluster_environment
  task_definition = aws_ecs_task_definition.td[count.index].arn
  desired_count   = 1

  load_balancer {
    target_group_arn = var.applications[count.index].target_group_arn
    container_name = format(
      "%s-%s-%s",
      var.applications[count.index].name,
      var.applications[count.index].type,
      var.cluster_environment
    )
    container_port = var.applications[count.index].port
  }

  tags = {
    "Provider"    = "terraform"
    "Environment" = var.cluster_environment,
  }
}
