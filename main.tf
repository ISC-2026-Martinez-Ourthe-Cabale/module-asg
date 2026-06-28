## Main del módulo ASG que contiene el Launch Template y el Auto Scaling Group.
## El Launch Template define la configuración de las instancias EC2, incluyendo el user data para instalar Docker y ejecutar un contenedor Nginx.
resource "aws_launch_template" "TF-LT-Obligatorio" {

  name_prefix = "AWS-${var.name}"

  image_id      = var.ami
  instance_type = var.instance_type

  iam_instance_profile {
    name = "LabInstanceProfile"
  }

  vpc_security_group_ids = [
    var.ec2_security_group_id
  ]

  user_data = base64encode(<<-EOF
#!/bin/bash

dnf update -y
dnf install -y docker git mariadb105

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user

cat > .env <<EOL
DB_HOST=${var.db_host}
DB_NAME=${var.db_name}
DB_USER=${var.db_username}
DB_PASSWORD=${var.db_password}
EOL

set -a
source .env
set +a

sleep 10

docker login registry.gitlab.com \
  -u deploy-token \
  -p ${var.gitlab_token}

docker run -d \
  -p 80:80 \
  -e DB_HOST=${var.db_host} \
  -e DB_NAME=${var.db_name} \
  -e DB_USER=${var.db_username} \
  -e DB_PASSWORD=${var.db_password} \
  registry.gitlab.com/mourthecabalediaz/app:1.0

EOF
  )

  tag_specifications {

    resource_type = "instance"

    tags = {
      Name = "${var.name}-EC2"
    }
  }

  monitoring {
    enabled = true
  }
}

## Auto Scaling Group que utiliza el Launch Template definido anteriormente.
resource "aws_autoscaling_group" "TF-ASG-Obligatorio" {

  name = "${var.name}-ASG"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  default_instance_warmup  = var.instance_warmup
  health_check_type         = "ELB"
  health_check_grace_period = var.instance_warmup

  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns = [
    var.target_group_arn
  ]

  launch_template {

    id      = aws_launch_template.TF-LT-Obligatorio.id
    version = "$Latest"
  }

  tag {

    key                 = "Name"
    value               = "${var.name}-EC2"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "traffic_target_tracking" {
  name                   = "${var.name}-trafico-escalado"
  autoscaling_group_name = aws_autoscaling_group.TF-ASG-Obligatorio.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.alb_resource_label
    }

    target_value       = var.requests_per_target
    disable_scale_in   = false
  }
}

## Esta politica intenta mantener el promedio de CPU del grupo alrededor de 80%.
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.name}-cpu-escalado"
  autoscaling_group_name = aws_autoscaling_group.TF-ASG-Obligatorio.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = var.cpu_target_value
    disable_scale_in = false
  }
}