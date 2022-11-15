# --- compute/outputs.tf ---

output "app_asg" {
  value = aws_autoscaling_group.amazic_app
}

output "app_backend_asg" {
  value = aws_autoscaling_group.amazic_backend
}
