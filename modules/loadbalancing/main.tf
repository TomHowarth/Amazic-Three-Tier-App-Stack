# --- loadbalancing/main.tf ---


# INTERNET FACING LOAD BALANCER

resource "aws_lb" "amazic_lb" {
  name            = "amazic-loadbalancer"
  security_groups = [var.lb_sg]
  subnets         = var.public_subnets
  idle_timeout    = 400

  depends_on = [
    var.app_asg
  ]
}

resource "aws_lb_target_group" "amazic_tg" {
  name     = "amazic-lb-tg-${substr(uuid(), 0, 3)}"
  port     = var.tg_port
  protocol = var.tg_protocol
  vpc_id   = var.vpc_id

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "amazic_lb_listener" {
  load_balancer_arn = aws_lb.amazic_lb.arn
  port              = var.listener_port
  protocol          = var.listener_protocol
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.amazic_tg.arn
  }
}
