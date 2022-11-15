# --- compute/main.tf ---


# LATEST AMI FROM PARAMETER STORE

data "aws_ssm_parameter" "amazic_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


# LAUNCH TEMPLATES AND AUTOSCALING GROUPS FOR BASTION

resource "aws_launch_template" "amazic_bastion" {
  name_prefix            = "amazic-bastion"
  instance_type          = var.instance_type
  image_id               = data.aws_ssm_parameter.amazic_ami.value
  vpc_security_group_ids = [var.bastion_sg]
  key_name               = var.key_name

  tags = {
    Name = "amazic_bastion"
  }
}

resource "aws_autoscaling_group" "amazic_bastion" {
  name                = "amazic-bastion"
  vpc_zone_identifier = var.public_subnets
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  launch_template {
    id      = aws_launch_template.amazic_bastion.id
    version = "$Latest"
  }
}


# LAUNCH TEMPLATES AND AUTOSCALING GROUPS FOR FRONTEND APP TIER

resource "aws_launch_template" "amazic_app" {
  name_prefix            = "amazic-app"
  instance_type          = var.instance_type
  image_id               = data.aws_ssm_parameter.amazic_ami.value
  vpc_security_group_ids = [var.frontend_app_sg]
  user_data              = filebase64("install_apache.sh")
  key_name               = var.key_name

  tags = {
    Name = "amazic_app"
  }
}

data "aws_lb_target_group" "amazic_tg" {
  name = var.lb_tg_name
}

resource "aws_autoscaling_group" "amazic_app" {
  name                = "amazic-app"
  vpc_zone_identifier = var.private_subnets
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2

  target_group_arns = [data.aws_lb_target_group.amazic_tg.arn]

  launch_template {
    id      = aws_launch_template.amazic_app.id
    version = "$Latest"
  }
}


# LAUNCH TEMPLATES AND AUTOSCALING GROUPS FOR BACKEND

resource "aws_launch_template" "amazic_backend" {
  name_prefix            = "amazic-backend"
  instance_type          = var.instance_type
  image_id               = data.aws_ssm_parameter.amazic_ami.value
  vpc_security_group_ids = [var.backend_app_sg]
  key_name               = var.key_name
  user_data              = filebase64("install_node.sh")

  tags = {
    Name = "amazic_backend"
  }
}

resource "aws_autoscaling_group" "amazic_backend" {
  name                = "amazic-backend"
  vpc_zone_identifier = var.private_subnets
  min_size            = 2
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.amazic_backend.id
    version = "$Latest"
  }
}

# AUTOSCALING ATTACHMENT FOR APP TIER TO LOADBALANCER

resource "aws_autoscaling_attachment" "asg_attach" {
  autoscaling_group_name = aws_autoscaling_group.amazic_app.id
  lb_target_group_arn    = var.lb_tg
}
