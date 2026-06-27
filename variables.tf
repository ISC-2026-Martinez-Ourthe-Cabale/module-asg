## Variables para el módulo de Auto Scaling Group (ASG)
variable "name" {
  description = "Nombre base para los recursos creados por el módulo ASG"
  type = string
}

variable "private_subnet_ids" {
  description = "Lista de IDs de subnets privadas para el ASG"
  type = list(string)
}

variable "ec2_security_group_id" {
  description = "ID del Security Group para las instancias EC2 del ASG"
  type = string
}

variable "target_group_arn" {
  description = "ARN del Target Group para el ASG"
  type = string
}

variable "instance_type" {
  description = "Tipo de instancia EC2 para el ASG"
  type    = string
  default = "t3.micro"
}

variable "ami" {
  description = "AMI para las instancias EC2 del ASG"
  type = string
}

variable "db_host" {
  description = "Host de la base de datos para la aplicación"
  type = string
}

variable "db_name" {
  description = "Nombre de la base de datos para la aplicación"
  type = string
}

variable "db_username" {
  description = "Nombre de usuario de la base de datos para la aplicación"
  type = string
}

variable "db_password" {
  description = "Contraseña de la base de datos para la aplicación"
  type = string
}

variable "gitlab_token" {
  description = "Token de acceso para el registro de GitLab"
  sensitive = true
}

variable "min_size" {
  description = "Número mínimo de instancias en el ASG"
  type    = number
  default = 2
}

variable "max_size" {
  description = "Número máximo de instancias en el ASG"
  type    = number
  default = 4
}

variable "desired_capacity" {
  description = "Número deseado de instancias en el ASG"
  type    = number
  default = 2
}

variable "alb_resource_label" {
  description = "Identificador combinado del ALB y Target Group"
  type        = string
}

variable "requests_per_target" {
  description = "Solicitudes por minuto permitidas por instancia"
  type        = number
  default     = 1000
}

variable "instance_warmup" {
  description = "Tiempo estimado de inicialización de una instancia"
  type        = number
  default     = 180
}