# --- root/main.tf ---

provider "aws" {
  region = var.location
  access_key = "AKIAY7FS5OFSRIU2AYJY"
  secret_key = "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"
  endpoints {
     sts = "https://sts.eu-west-2.amazonaws.com"
  }
}

locals {
  cwd           = reverse(split("/", path.cwd))
  instance_type = var.instance_type
  environment   = var.env
  vpc_cidr      = "10.123.0.0/16" #var.vpc_cidr
}

module "networking" {
  source            = "../../modules/networking"
  vpc_cidr          = local.vpc_cidr
  access_ip         = var.access_ip
  public_sn_count   = 2
  private_sn_count  = 2
  db_subnet_group   = true
  availabilityzone  = "eu-west-2a" # var.location
  azs               = 2
}

module "compute" {
  source                  = "../../modules/compute"
  frontend_app_sg         = module.networking.frontend_app_sg
  backend_app_sg          = module.networking.backend_app_sg
  bastion_sg              = module.networking.bastion_sg
  public_subnets          = module.networking.public_subnets
  private_subnets         = module.networking.private_subnets
  bastion_instance_count  = 1
  instance_type           = local.instance_type
  key_name                = "TestKeyPair"
  lb_tg_name              = module.loadbalancing.lb_tg_name
  lb_tg                   = module.loadbalancing.lb_tg
}

module "database" {
  source               = "../../modules/database"
  db_storage           = 10
  db_engine_version    = "5.7"
  db_instance_class    = "db.t2.micro"
  db_name              = var.db_name
  dbuser               = var.dbuser
  dbpassword           = var.dbpassword
  db_identifier        = "amazic-db"
  skip_db_snapshot     = true
  rds_sg               = module.networking.rds_sg
  db_subnet_group_name = module.networking.db_subnet_group_name[0]
}

module "loadbalancing" {
  source                  = "../../modules/loadbalancing"
  lb_sg                   = module.networking.lb_sg
  public_subnets          = module.networking.public_subnets
  tg_port                 = 80
  tg_protocol             = "HTTP"
  vpc_id                  = module.networking.vpc_id
  app_asg                 = module.compute.app_asg
  listener_port           = 80
  listener_protocol       = "HTTP"
  azs                     = 2
}
