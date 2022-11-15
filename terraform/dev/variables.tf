# --- root/variables.tf ---

variable "access_ip" {
  type = string
}

variable "db_name" {
  type = string
}

variable "dbuser" {
  type      = string
  sensitive = true
}

variable "dbpassword" {
  type      = string
  sensitive = true
}

variable "location" {
  type = string
}

variable "instance_type" {
  type = string
}
variable "env" {
  type = string # p = prod, d = dev, s = staging, t = test, r = recovery
}
