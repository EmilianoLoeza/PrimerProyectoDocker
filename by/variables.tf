variable "aws_region" {
  description = "Region de AWS. Debe coincidir con la del pipeline."
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Prefijo de recursos y nombre del repositorio de ECR."
  type        = string
  default     = "primerproyectodocker"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "El nombre debe tener maximo 20 caracteres, comenzar con minuscula y contener solo minusculas, numeros o guiones."
  }
}

variable "database_name" {
  description = "Nombre de la base de datos inicial de MySQL."
  type        = string
  default     = "appdb"
}

