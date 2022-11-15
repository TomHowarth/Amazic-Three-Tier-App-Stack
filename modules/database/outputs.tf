# --- database/outputs.tf ---

output "db_endpoint" {
  value = aws_db_instance.amazic_db.endpoint
}
