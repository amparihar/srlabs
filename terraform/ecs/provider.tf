provider "aws" {
  region = var.aws_regions[var.aws_region]
}

# --------------------------------------------------------------
# VPC
# --------------------------------------------------------------
module "vpc" {
  source     = "./modules/vpc"
  app_name   = var.app_name
  stage_name = var.stage_name
}

output "vpcid" {
  value = [module.vpc.vpcid]
}

# --------------------------------------------------------------
# ALB
# --------------------------------------------------------------

module "alb" {
  source     = "./modules/load-balancer"
  app_name   = var.app_name
  stage_name = var.stage_name
  vpcid      = module.vpc.vpcid
  subnets    = module.vpc.public_subnet_ids
}

output "alb_arn" {
  value = module.alb.arn
}

output "alb_dns_name" {
  value = module.alb.dns_name
}

# --------------------------------------------------------------
# ECS Fargate
# --------------------------------------------------------------
module "fargate-cluster" {
  source                = "./modules/cluster"
  app_name              = var.app_name
  stage_name            = var.stage_name
  regionid              = var.aws_regions[var.aws_region]
  ecs_cluster_name      = var.ecs_cluster_name
  vpcid                 = module.vpc.vpcid
  subnets               = module.vpc.public_subnet_ids
  alb_security_group_id = module.alb.security_group_id
  alb_dns_name          = module.alb.dns_name[0]
  target_groups = {
    "front_end_microservice" = module.alb.front_end_microservice_target_group_arn
  }
}

