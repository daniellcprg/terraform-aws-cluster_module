output "applications" {
  value = tolist(
    [for i, e in var.applications : 
      {
        application_name = format("%s-%s", e.name, e.type)
        application_port = e.port
        ecr_repository_url = aws_ecr_repository.main[i].repository_url
        ecs_service_name = format("%s-%s-%s", e.name, e.type, var.cluster_environment)
        ecs_task_family = format("%s-%s-%s", e.name, e.type, var.cluster_environment)
      }
    ]
  )
}