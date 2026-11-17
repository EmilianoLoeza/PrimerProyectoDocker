output "aws_region" {
  description = "Region configurada"
  value       = var.aws_region
}

output "ecr_repository_url" {
  description = "Direccion de ECR para subir la imagen Docker"
  value       = aws_ecr_repository.app.repository_url
}

output "ec2_nginx_url" {
  description = "Pagina HTTP de Nginx en la EC2"
  value       = "http://${aws_instance.nginx.public_ip}"
}

output "ecs_app_url" {
  description = "Pagina HTTP de la aplicacion en Fargate"
  value       = "http://${aws_lb.app.dns_name}"
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.app.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "rds_endpoint" {
  description = "Endpoint privado de MySQL (no es accesible desde Internet)"
  value       = aws_db_instance.mysql.endpoint
}

output "github_actions_role_arn" {
  description = "ARN del rol utilizado por GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}