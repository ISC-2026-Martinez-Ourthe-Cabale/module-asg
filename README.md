⚖️ module-asg
Repositorio: `ISC-2026-Martinez-Ourthe-Cabale/module-asg`  
Lenguaje: HCL (Terraform)
## Descripción
Crea el Launch Template y el Auto Scaling Group para las instancias EC2 que ejecutan la aplicación. El user data del Launch Template instala Docker, descarga la imagen de la aplicación desde GitLab Container Registry y la ejecuta inyectando las variables de conexión a la base de datos.
Recursos que crea
## Recursos Creados

| Recurso AWS | Descripción |
|-------------|-------------|
| `aws_launch_template` | Configuración de instancias EC2 (AMI, tipo, user data, Security Group, IAM Instance Profile) |
| `aws_autoscaling_group` | Auto Scaling Group encargado de gestionar el ciclo de vida de las instancias EC2 |

## Configuración del Auto Scaling Group

| Parámetro | Valor |
|------------|-------|
| Capacidad mínima | `2` instancias |
| Capacidad máxima | `4` instancias |
| Capacidad deseada | `2` instancias |
| Health check type | `ELB` |
| Subnets | Subnets privadas APP (ambas AZs) |
| IAM Instance Profile | `LabInstanceProfile` |

## User Data (Bootstrap de Instancias)

Al lanzar cada instancia, el script de *user data* realiza automáticamente:

- Actualiza el sistema operativo (`dnf update -y`).
- Instala Docker, Git y el cliente MySQL (`mariadb105`).
- Habilita e inicia el servicio Docker.
- Agrega el usuario `ec2-user` al grupo `docker`.
- Crea un archivo `.env` con las variables de conexión a la base de datos.
- Autentica contra GitLab Container Registry utilizando el deploy token.
- Ejecuta el contenedor de la aplicación (`registry.gitlab.com/mourthecabalediaz/app:1.0`) exponiendo el puerto `80` e inyectando las variables de entorno necesarias para la conexión a la base de datos.

## Variables de Entrada

| Variable | Tipo | Descripción |
|----------|------|-------------|
| `name` | `string` | Nombre del proyecto para tags |
| `ami` | `string` | ID de la AMI para las instancias |
| `instance_type` | `string` | Tipo de instancia EC2 (ej: `t3.micro`) |
| `ec2_security_group_id` | `string` | ID del Security Group de EC2 |
| `private_subnet_ids` | `list(string)` | IDs de las subnets privadas APP |
| `target_group_arn` | `string` | ARN del Target Group del ALB |
| `db_host` | `string` | Endpoint del RDS |
| `db_name` | `string` | Nombre de la base de datos |
| `db_username` | `string` | Usuario de la base de datos |
| `db_password` | `string` | Contraseña de la base de datos |
| `gitlab_token` | `string` | Token de despliegue del GitLab Container Registry |

## Outputs

| Output | Descripción |
|---------|-------------|
| `asg_name` | Nombre del Auto Scaling Group |
| `launch_template_id` | ID del Launch Template |
Uso como módulo
```hcl
module "ec2_asg" {
  source = "git::ssh://git@github.com/ISC-2026-Martinez-Ourthe-Cabale/module-asg.git"

  name                   = "Obligatorio"
  ami                    = var.ami
  instance_type          = "t3.micro"
  ec2_security_group_id  = module.security_groups.ec2_security_group_id
  private_subnet_ids     = module.networking.private_app_subnet_ids
  target_group_arn       = module.alb.target_group_arn
  db_host                = module.database.db_endpoint
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  gitlab_token           = var.gitlab_token
}
```
---
---
